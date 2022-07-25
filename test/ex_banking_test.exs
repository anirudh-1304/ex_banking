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
      assert {:ok, _bal} = ExBanking.deposit("testuser1", 100, "usd")
      assert {:ok, 100.0} = ExBanking.get_balance("testuser1", "usd")
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
end
