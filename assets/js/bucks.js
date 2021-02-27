import React, { useState, useEffect } from 'react';
import { ch_join, ch_push, ch_start } from './socket';

// Modified from CS 4550 lecture notes
// Author: Nat Tuck
// Attribution: https://github.com/NatTuck/scratch-2021-01/blob/master/notes-4550/04-react-intro/notes.md

function Login({ state, addPlayer, addSpectator, setState }) {
  const [gameRoomInput, setGameRoomInput] = useState("");
  const [userNameInput, setUserNameInput] = useState(state.username);
  
  function updateUserName(ev) {
    setUserNameInput(ev.target.value);
  }

  function updateGameRoom(ev) {
    let game = ev.target.value;
    setGameRoomInput(ev.target.value);
  }

  function makeNewPlayer() {
    addPlayer(gameRoomInput, userNameInput);
  }

  function makeNewSpectator() {
    addSpectator(gameRoomInput, userNameInput);
  }
  
  return (
    <div>
      <h1>Bucks and Does: Multiplayer</h1>
      <h2>Login</h2>
      <label for="groom">Game Room:</label>
      <input
        type="text"
        id="groom"
        name="groom"
        value={gameRoomInput}
        onChange={updateGameRoom}
      />
      <label for="uname">Username:</label>
      <input
        type="text"
        id="uname"
        name="uname"
        value={userNameInput}
        onChange={updateUserName}
      />
      <button onClick={makeNewPlayer}>Play!</button>
      <button onClick={makeNewSpectator}>Spectate!</button>
    </div>
  );
}

function Setup({ state, setState }) {

  function makeReady() {
    ch_push("ready", "");
  }
  
  function exitSetup() {
    window.location.reload(false);
  }

  return (
    <div>
      <h1>Bucks and Does: Multiplayer</h1>
      <h2>Setup</h2>
      <table>
        <thead>
          <tr>
            <th>Username</th>
            <th>Status</th>
            <th>Total Wins</th>
            <th>Total Losses</th>
          </tr>
        </thead>
        <tbody>
          {Object.entries(state.users).map((user) =>
            <tr key={user[0]}>
              <td>{user[0]}</td>
              <td>{user[1][0]}</td>
              <td>{user[1][1]}</td>
              <td>{user[1][2]}</td>
            </tr>
          )}
        </tbody>
      </table>
      <button onClick={makeReady}>I'm Ready!</button>
      <button onClick={exitSetup}>Back To Login?</button>
      <h2>Winners From The Last Game:</h2>
        {state.winners.map((winner) =>
        (<ul>
        <li>{winner}</li>
        </ul>))}
    </div>
  );
}

function Gameplay({ reset, state, setState }) {
  const [guessInput, setGuessInput] = useState("");

  function updateGuess(ev) {
    setGuessInput(ev.target.value);
  }
  
  function makeGuess() {
    ch_push("guess", {number: guessInput});
    setGuessInput("");
  }
  
  function makePass() {
    ch_push("guess", {number: "PASS"});
    setGuessInput("");
  }
  
  function onKeyPress(ev) {
    if (ev.key === "Enter") {
      makeGuess();
    }
  }
  
  function exitGame() {
    ch_push("reset", "");
    setCurrentGuess("");
  }

  function displayGuesses(data) {
    return data[1].map((guess, index) =>
        <tr key={String(data[0])}>
          <td>{data[0]}</td>
          <td>{guess.guess}</td>
          <td>{`${guess.bucks}`}</td>
          <td>{`${guess.does}`}</td>
        </tr>
    );
  }

  return (
    <div>
      <h1>Bucks and Does: Multiplayer</h1>
      <h2>How To Play:</h2>
      <p>
        Attempt to crack the secret code!<br/>
        Bucks: Each digit that is in the correct position and is in the code.<br/>
        Does: Each digit that is in the wrong position but is in the code.
      </p>
      <h2>The Rules:</h2>
      <p>
        The secret code is four digits.<br/>
        Each digit in the code is unique (0-9).<br/>
        You have 30 seconds to make a guess.<br/>
        It is possible to have multiple winners.
      </p>
      <h2>Guess The Code:</h2>
      <p class="alert alert-warning" role="alert">{state.message}</p>
      <label>
        <input
          type="text"
          value={guessInput}
          onChange={updateGuess}
          onKeyPress={onKeyPress}
          maxlength="4"
        />
        <button onClick={makeGuess}>Try It!</button>
        <button onClick={makePass}>Pass...</button>
        <button
          type="button"
          class="btn btn-secondary"
          onClick={exitGame}>Back To Setup?
        </button>
      </label>
      <h2>Previous Attempts:</h2>
      <table>
        <thead>
          <tr>
            <th>Username</th>
            <th>Guess</th>
            <th>Bucks</th>
            <th>Does</th>
          </tr>
        </thead>
        <tbody>
          {Object.entries(state.guesses).map((guesses) =>
            displayGuesses(guesses)
          )}
        </tbody>
      </table>
    </div>
  );
}

function Bucks() {
  const [state, setState] = useState({
    guesses: [],
    users: [],
    winners: [],
    setup: true,
    message: "",
    username: "",
  });

  function setStateDefault(st){
    let new_state = Object.assign(st, {username: state.username})
    setState(new_state)
  }

  function setUserName(name){
    let new_state = state
    new_state.username = name
    setState(new_state)
  }

  useEffect(() => ch_join(setStateDefault));

  function addPlayer(gameroom, username) {
    setUserName(username)
    ch_start(gameroom, { player: username });
  }

  function addSpectator(gameroom, username) {
    setUserName(username)
    ch_start(gameroom, { spectator: username });
  }

  function reset() {
    ch_push("reset", "");
  }

  if (!(state.username in state.users)) {
    return (
      <Login
        state={state}
        addPlayer={addPlayer}
        addSpectator={addSpectator}
        setState={setState}
      />
    );
  }
  else if (state.setup) {
    return (
      <Setup
        state={state}
        setState={setState}
      />
    );
  }
  else {
    return (
      <Gameplay
        reset={reset}
        state={state}
        setState={setState}
      />
    );
  }
}

export default Bucks;
