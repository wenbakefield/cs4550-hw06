import React, { useState, useEffect } from 'react';
import { ch_join, ch_push } from './socket';

// Attribution: Based on lecture notes from CS 4550
// Author: Nat Tuck
// Link: https://github.com/NatTuck/scratch-2021-01/blob/master/notes-4550/04-react-intro/notes.md
function Bucks() {
  const [state, setState] = useState({
    guesses: [],
    win: false,
    lose: false,
    msg: "",
  });
  
  const [guessInput, setGuessInput] = useState("");
  
  useEffect(() => {
    ch_join(setState);
  });
  
  function updateGuess(ev) {
    setGuessInput(ev.target.value);
  }
  
  function makeGuess() {
      ch_push("guess", {number: guessInput});
      setGuessInput("");
      
  }
  
  function onKeyPress(ev) {
    if (ev.key === "Enter") {
      makeGuess();
    }
  }

  function newGame() {
    ch_push("new", "");
  }

  return (
    <div>
      <h1>Bucks and Does</h1>
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
        You cannot try the same guess twice.<br/>
        You only have eight attempts.
      </p>
      <h2>Guess The Code:</h2>
      <p class="alert alert-warning" role="alert">{state.msg}</p>
      <p class="alert alert-success" role="alert">{state.win ? "You Win!" : ""}</p>
      <p class="alert alert-danger" role="alert">{state.lose ? "You Lose..." : ""}</p>
      <label>
        <input
          type="text"
          value={guessInput}
          onChange={updateGuess}
          onKeyPress={onKeyPress}
          maxlength="4"
          disabled={(state.lose || state.win) ? "disabled" : ""}
        />
        <button onClick={makeGuess} disabled={(state.lose || state.win) ? "disabled" : ""}>Try It!</button>
        <button onClick={newGame}>New Game</button>
      </label>
      <h2>Previous Attempts:</h2>
      <table>
        <thead>
          <tr>
            <th>Attempt</th>
            <th>Guess</th>
            <th>Bucks</th>
            <th>Does</th>
          </tr>
        </thead>
        <tbody>
          {state.guesses.map((guess, index) => 
            <tr key={index}>
              <td>{index + 1}</td>
              <td>{guess.guess}</td>
              <td>{`${guess.bucks}`}</td>
              <td>{`${guess.does}`}</td>
            </tr>)
          }
        </tbody>
      </table>
    </div>
  );
}

export default Bucks;
