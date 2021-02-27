defmodule BullsWeb.GameChannel do
  @moduledoc """
  Modified from CS 4550 lecture notes
  Author: Nat Tuck
  Attribution: https://github.com/NatTuck/scratch-2021-01/blob/master/4550/0219/hangman/lib/hangman_web/channels/game_channel.ex
  """
  use BullsWeb, :channel
  
  alias Bulls.Game
  alias Bulls.GameServer

  @impl true
  def join("game:" <> name, %{"player" => player}, socket) do
    do_join(name, {player, :player}, socket)
  end

  @impl true
  def join("game:" <> name, %{"spectator" => spectator}, socket) do
    do_join(name, {spectator, :spectator}, socket)
  end
  
  defp do_join(name, {username, _} = user, socket) do
    GameServer.start(name)
    GameServer.join(name, user)
    socket = socket
    |> assign(:name, name)
    |> assign(:user, username)
    view = GameServer.view(name)
    send(self(), :user_join)
    {:ok, view, socket}
  end
  
  @impl true
  def handle_info(:user_join, socket) do
    name = socket.assigns[:name]
    view = GameServer.view(name)
    broadcast(socket, "view", view)
    {:noreply, socket}
  end
  
  @impl true
  def handle_in("ready", _payload, socket) do
    name = socket.assigns[:name]
    user = socket.assigns[:user]
    GameServer.ready(name, user)
    view = GameServer.view(name)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("guess", %{"number" => nn}, socket) do
    name = socket.assigns[:name]
    user = socket.assigns[:user]
    GameServer.guess(name, user, nn)
    view = GameServer.view(name)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("reset", _, socket) do
    name = socket.assigns[:name]
    GameServer.reset(name)
    view = GameServer.view(name)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
