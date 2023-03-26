/*
  Outputs text like a computer terminal with a flashing cursor:
**/
import React, { useState, useEffect } from 'react';

const ComputerOutput = ({ text }) => {
  const [displayText, setDisplayText] = useState('');
  const [showCursor, setShowCursor] = useState(true);

  useEffect(() => {
    let currentIndex = 0;

    const timer = setInterval(() => {
      if (currentIndex < text.length) {
        setDisplayText((prevText) => prevText + text.charAt(currentIndex));
        currentIndex++;
      } else {
        clearInterval(timer);
      }
    }, 50);

    return () => {
      clearInterval(timer);
    };
  }, [text]);

  useEffect(() => {
    const cursorTimer = setInterval(() => {
      setShowCursor((prev) => !prev);
    }, 500);

    return () => {
      clearInterval(cursorTimer);
    };
  }, []);

  return (
    <div>
      <span>{displayText}</span>
      {showCursor && <span className="cursor">|</span>}
    </div>
  );
};

export default ComputerOutput;
