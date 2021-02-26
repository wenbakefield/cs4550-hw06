defmodule Bulls.Game do
  @moduledoc """
  Modified from CS 4550 lecture notes
  Author: Nat Tuck
  Attribution: https://github.com/NatTuck/scratch-2021-01/blob/master/4550/0212/hangman/lib/hangman/game.ex
  """

  def new do
    %{
      secret: random_secret(),
      guesses: MapSet.new(),
      msg: ""
    }
  end

  def guess(st, number) do
    digits = String.graphemes(number)
    cond do
      loser?(st) ->
        %{ st | msg: "You cannot cheat by editing the input box HTML!" }
      winner?(st) ->
        %{ st | msg: "You have already won!" }
      !Regex.match?(~r{\A\d*\z}, number) ->
        %{ st | msg: "Each digit in your guess must be a number! (0-9)" }
      Enum.count(digits) != 4 ->
        %{ st | msg: "Your guess must be four digits long!" }
      Enum.uniq(digits) != digits ->
        %{ st | msg: "Each digit in your guess must be unique!" }
      Map.values(st.guesses) |> Enum.member?(number) ->
        %{ st | msg: "Your guess must not be a repeat of a previous guess!" }
      true ->
        %{ st | guesses: MapSet.put(st.guesses, number), msg: "" }
    end
  end

  def view(st) do
  results = fn (g) -> get_bucks_does(g, st.secret) end
    %{
      guesses: Enum.map(st.guesses, results),
      win: winner?(st),
      lose: loser?(st) and not winner?(st),
      msg: Map.get(st, :msg, "")
    }
  end
  
  defp winner?(st), do: st.secret in st.guesses
  
  defp loser?(st), do: MapSet.size(st.guesses) > 7
  
  defp get_bucks_does(guess, secret) do
    guess_digits = String.graphemes(guess)
    secret_digits = String.graphemes(secret)
    Map.put(Enum.reduce(Enum.zip(guess_digits, secret_digits),
      %{bucks: 0, does: 0}, 
      fn ({guess_digit, secret_digit}, %{bucks: bucks, does: does}) ->
        cond do
          guess_digit == secret_digit -> %{bucks: bucks + 1, does: does}
          guess_digit in secret_digits -> %{bucks: bucks, does: does + 1}
          true -> %{bucks: bucks, does: does}
        end
      end), :guess, guess)
  end

  defp random_secret() do
    Enum.join(Enum.take_random(0..9, 4))
  end
end
