# ExBanking

This Application provides simple banking OTP application in Elixir language to perform basic banking operations for users

## Steps to perform

1. Creating a user
  ExBanking.create_user("newtestuser")
  OUTPUT: :ok

2. Deposit ammount in user account
  ExBanking.deposit("newtestuser", 100, "usd")
  OUTPUT: {:ok, 100.0}

3. Withdraw ammount from user account
  ExBanking.withdraw("newtestuser", 5, "usd")
  OUTPUT: {:ok, 95.0}

  
4. Getting current balance of user account for a _currency
  ExBanking.get_balance("newtestuser", "usd")
  OUTPUT: {:ok, 95.0}

5. Tranfer money from one user to another
  ExBanking.create_user("newtestuser2")
  ExBanking.send("newtestuser", "newtestuser2", 5, "usd")
  OUTPUT: {:ok, 90.0, 5.0}

All the above requests for particular user are limited to 10requests pending at a time and if we get more than that will get the below error:
{:error, :too_many_requests_to_user}
