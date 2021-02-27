defmodule Bulls.Game do
  @moduledoc """
  Modified from CS 4550 lecture notes
  Author: Nat Tuck
  Attribution: https://github.com/NatTuck/scratch-2021-01/blob/master/4550/0212/hangman/lib/hangman/game.ex
  
  Modified from Assignment 5
  Author: Ben Wakefield
  Attribution: https://github.com/wenbakefield/cs4550-hw05/blob/main/lib/bulls/game.ex
  
  Large amount of code for game logic modified from Assignment 6
  Functions effected:
    -user_join()
    -user_ready()
    -guess()
    -guessed_already?
    -all_guessed
    -end_round
    -pass_player
    -end_game
    -end_game_player
    -view
    -view_guesses
    -view_guess
    -view_user
    -get_winners
  Author: Brian Austin
  Attribution: https://github.com/brianjaustin/cs4550-hw06/blob/main/lib/hw06/game.ex
  """

  def new(next) do
    %{
      secret: "1234",
      guesses: Map.new(),
      users: Map.new(),
      winners: [],
      messages: Map.new(),
      round: 0,
      nextround: next
    }
  end

  def user_join(st, {username, :player}) do
    cond do
      username in Map.keys(st.users) -> st
      st.round > 0 -> %{st | users: Map.put(st.users, username, :spectator)}
      true -> %{st | users: Map.put(st.users, username, {:waiting, 0, 0})}
    end
  end

  def user_join(st, {username, :spectator}) do
    cond do
      username in Map.keys(st.users) -> st
      true -> %{st | users: Map.put(st.users, username, :spectator)}
    end
  end

  def user_ready(st, username) do
    case Map.get(st.users, username) do
      {:waiting, wins, losses} ->
        result = %{
          st
          | users: Map.put(st.users, username, {:player, wins, losses}),
            guesses: Map.put(st.guesses, username, [])
        }

        if Enum.all?(result.users, fn
             {_, {type, _, _}} -> type != :waiting
             _ -> true
           end) do
          st.nextround.(1)
          %{result | round: 1}
        else
          result
        end

      _ ->
        st
    end
  end

  def guess(st, player, number) do
    digits = String.graphemes(number)

    cond do
      Map.get(st.users, player, :spectator) == :spectator ->
        %{st | messages: Map.put(st.messages, player, "Spectators cannot make guesses!")}
      
      number == "PASS" ->
        player_guesses = Map.get(st.guesses, player, [])
        player_guesses = [{"PASS", st.round} | player_guesses]
        result = %{st | guesses: Map.put(st.guesses, player, player_guesses)}

        if all_guessed?(result) do
          end_round(result, st.round)
        else
          result
        end

      !Regex.match?(~r{\A\d*\z}, number) ->
        %{
          st
          | messages:
              Map.put(st.messages, player, "Each digit in your guess must be a number! (0-9)")
        }

      Enum.count(digits) != 4 ->
        %{st | messages: Map.put(st.messages, player, "Your guess must be four digits long!")}

      Enum.uniq(digits) != digits ->
        %{st | messages: Map.put(st.messages, player, "Each digit in your guess must be unique!")}

      true ->
        player_guesses = Map.get(st.guesses, player, [])

        cond do
          guessed_already?(st, player_guesses) ->
            st

        true ->
          player_guesses = [{number, st.round} | player_guesses]
          result = %{st | guesses: Map.put(st.guesses, player, player_guesses)}

          if all_guessed?(result) do
            end_round(result, st.round)
          else
            result
          end
        end
    end
  end

  defp guessed_already?(_, []), do: false
  defp guessed_already?(st, [{_, round} | _]), do: st.round == round

  defp all_guessed?(st) do
    guesses_this_round =
      st.guesses
      |> Enum.flat_map(fn {_, gs} -> gs end)
      |> Enum.filter(fn {_, r} -> st.round == r end)
      |> Enum.count()

    players =
      st.users
      |> Enum.filter(fn
        {_, {role, _, _}} -> role == :player
        _ -> false
      end)
      |> Enum.count()

    guesses_this_round == players
  end

  def end_round(st, round) do
    cond do
      st.round != round ->
        st

      Enum.empty?(get_winners(st)) ->
        new_round = st.round + 1

        guesses =
          st.guesses
          |> Enum.map(fn {player, guesses} -> {player, pass_player(st, guesses)} end)
          |> Enum.into(%{})

        st.nextround.(new_round)
        %{st | guesses: guesses, round: new_round}

      true ->
        end_game(st)
    end
  end

  defp pass_player(st, guesses) do
    if not guessed_already?(st, guesses) do
      [{"PASS", st.round} | guesses]
    else
      guesses
    end
  end

  def end_game(st) do
    guesses =
      st.users
      |> Enum.map(fn {p, _} -> {p, []} end)
      |> Enum.into(%{})

    users =
      st.users
      |> Enum.map(&end_game_player(st, &1))
      |> Enum.into(%{})

    %{
      st
      | secret: random_secret(),
        guesses: guesses,
        users: users,
        winners: get_winners(st),
        messages: Map.new(),
        round: 0
    }
  end

  defp end_game_player(st, {player, {:player, wins, losses}}) do
    winners = get_winners(st)

    cond do
      Enum.count(winners) < 1 ->
        {player, {:waiting, wins, losses}}

      player in winners ->
        {player, {:waiting, wins + 1, losses}}

      true ->
        {player, {:waiting, wins, losses + 1}}
    end
  end

  defp end_game_player(_, user), do: user

  def view(st) do
    guess_views =
      st.guesses
      |> Enum.map(&view_guesses(&1, st))
      |> Enum.into(%{})

    users =
      st.users
      |> Enum.map(&view_user/1)
      |> Enum.into(%{})

    %{
      guesses: guess_views,
      setup: st.round == 0,
      users: users,
      winners: st.winners,
      messages: st.messages
    }
  end

  defp view_guesses({player, guesses}, st) do
    guesses =
      guesses
      |> Enum.drop_while(fn {_, round} -> round == st.round end)
      |> Enum.map(&view_guess(&1, st.secret))
      |> Enum.reverse()

    {player, guesses}
  end

  defp view_guess({guess, _}, secret) do
    guess_digits = String.graphemes(guess)
    secret_digits = String.graphemes(secret)

    Map.put(
      Enum.reduce(
        Enum.zip(guess_digits, secret_digits),
        %{bucks: 0, does: 0},
        fn {guess_digit, secret_digit}, %{bucks: bucks, does: does} ->
          cond do
            guess_digit == secret_digit -> %{bucks: bucks + 1, does: does}
            guess_digit in secret_digits -> %{bucks: bucks, does: does + 1}
            true -> %{bucks: bucks, does: does}
          end
        end
      ),
      :guess,
      guess
    )
  end

  defp view_user({username, {_, _, _} = metadata}) do
    {username, Tuple.to_list(metadata)}
  end

  defp view_user({username, role}) do
    {username, [role, 0, 0]}
  end

  defp get_winners(st) do
    Enum.reduce(st.guesses, [], fn {player, guesses}, rest ->
      player_guesses = Enum.map(guesses, fn {guess, _} -> guess end)
      if st.secret in player_guesses, do: [player | rest], else: rest
    end)
  end

  defp random_secret() do
    Enum.join(Enum.take_random(0..9, 4))
  end
end
