defmodule BullsWeb.GameChannel do
  @moduledoc """
  Modified from CS 4550 lecture code
  Author: Nat Tuck
  Attribution: https://github.com/NatTuck/scratch-2021-01/blob/master/4550/0212/hangman/lib/hangman_web/channels/game_channel.ex
  """
  use BullsWeb, :channel

  @impl true
  def join("game:" <> _id, payload, socket) do
    if authorized?(payload) do
      game = Bulls.Game.new()
      socket = assign(socket, :game, game)
      view = Bulls.Game.view(game)
      {:ok, view, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("guess", %{"number" => nn}, socket) do
    game0 = socket.assigns[:game]
    game1 = Bulls.Game.guess(game0, nn)
    socket = assign(socket, :game, game1)
    view = Bulls.Game.view(game1)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("new", _, socket) do
    game = Bulls.Game.new()
    socket = assign(socket, :game, game)
    view = Bulls.Game.view(game)
    {:reply, {:ok, view}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
