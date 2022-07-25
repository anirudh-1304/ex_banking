defmodule ExBankingTest do
  use ExUnit.Case

  setup_all do
    ExBanking.create_user("testuser1")
    ExBanking.create_user("testuser2")
    :ok
  end

  describe "&create_user/1" do
    test "test to create new user" do
      ExBanking.create_user("newtestuser")
      refute Registry.lookup(Registry.Users, "newtestuser") == []
    end

    test "test to get error as user already exists" do
      assert ExBanking.create_user("testuser1") == {:error, :user_already_exists}
    end
  end

  describe "&deposit/1" do
    test "test to deposit money into testuser1 account" do
      assert {:ok, _bal} = ExBanking.deposit("testuser1", 200, "usd")
    end

    test "test to get error response when depositing in invalid user" do
      assert ExBanking.deposit("invalid", 10, "usd") == {:error, :user_does_not_exist}
    end

    test "test to get error response when we give amount in string" do
      assert ExBanking.deposit("testuser1", "10", "usd") == {:error, :wrong_arguments}
    end

    test "test to get error response when there are too many requests" do
      ExBanking.create_user("test")

      request_count =
        1..50
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.deposit("test", 10, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_user} end)

      assert request_count >= 1
    end
  end

  describe "&withdraw/1" do
    test "test to withdraw amount from testuser2 successfully" do
      ExBanking.deposit("testuser2", 10, "usd")
      assert {:ok, _balance} = ExBanking.withdraw("testuser2", 10, "usd")
    end

    test "test to withdraw more money than the user actually have" do
      assert ExBanking.withdraw("testuser2", 100, "usd") == {:error, :not_enough_money}
    end

    test "test to get error response when user does not exist" do
      assert ExBanking.withdraw("invalid", 10, "usd") == {:error, :user_does_not_exist}
    end

    test "test to get error response when we give amount as string" do
      assert ExBanking.withdraw("testuser1", "25", "usd") == {:error, :wrong_arguments}
    end

    test "test to get error response when there is too many requests" do
      ExBanking.create_user("test")

      request_count =
        1..50
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.withdraw("test", 25, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_user} end)

      assert request_count >= 1
    end
  end

  describe "&get_balance/1" do
    test "test to get balance correctly" do
      assert {:ok, _balance} = ExBanking.get_balance("testuser1", "usd")
    end

    test "test to get error response when user does not exist" do
      assert ExBanking.get_balance("invalid", "usd") == {:error, :user_does_not_exist}
    end

    test "test to get error response when there is too many requests" do
      ExBanking.create_user("test")

      request_count =
        1..50
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.get_balance("test", "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_user} end)

      assert request_count >= 1
    end
  end

  describe "&send/1" do
    test "test to send money correctly" do
      ExBanking.deposit("testuser1", 5, "usd")
      assert {:ok, _from, _to} = ExBanking.send("testuser1", "testuser2", 5, "usd")
    end

    test "test to get error response when from user does not exist" do
      assert ExBanking.send("random", "testuser2", 5, "usd") == {:error, :sender_does_not_exist}
    end

    test "test to get error response when to user does not exist" do
      ExBanking.deposit("testuser1", 5, "usd")
      assert ExBanking.send("testuser1", "to", 5, "usd") == {:error, :receiver_does_not_exist}
    end

    test "test to get error response when we give bad args" do
      assert ExBanking.send("testuser1", "testuser2", "5", :usd) == {:error, :wrong_arguments}
    end

    test "test to get error response when there is too many requests for sender" do
      ExBanking.create_user("sender")
      ExBanking.create_user("receiver")

      error_count =
        1..100
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.send("sender", "receiver", 5, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_sender} end)

      assert error_count >= 1
    end

    test "test to get error response when there is too many requests for receiver" do
      ExBanking.create_user("sender")
      ExBanking.create_user("receiver")
      ExBanking.deposit("sender", 1000, "usd")

      error_count =
        1..100
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.send("sender", "receiver", 5, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_receiver} end)

      assert error_count >= 1
    end
  end
end
