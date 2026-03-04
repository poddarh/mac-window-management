import styles from "./styles.jsx";
import * as Uebersicht from 'uebersicht'

const containerStyle = {
  display: "grid",
  gridAutoFlow: "column",
  gridGap: "8px"
};

const desktopStyle = {};

// Note that this can change at any time
const getCurrentDisplayId = (displays) => {
  let displayIndex = window.location.pathname.split('/')[1];
  let display = displays.filter(display => display.id == displayIndex)[0];
  return display.index;
}

// Extract display number from space label (e.g., "space_03" -> 3)
const getDisplayNumber = (label) => {
  if (!label || label === "") return label;

  const match = label.match(/^space_0?(\d+)$/);
  if (match) {
    return parseInt(match[1]);
  }

  return label;
};

const renderSpace = (index, label, focused, visible, windows) => {
  let contentStyle = JSON.parse(JSON.stringify(desktopStyle));

  let name = getDisplayNumber(label);
  if (name === label || name === "" || name === undefined) {
    // Fallback for unlabeled or unrecognized labels
    name = "i" + index;
  }

  if (focused) {
    contentStyle.color = styles.colors.accent;
    contentStyle.fontWeight = "700";
  } else if (visible) {
    contentStyle.color = styles.colors.fg;
  } else if (windows.length == 0) {
    contentStyle.color = styles.colors.empty;
  }
  return (
    <div style={contentStyle}
      onClick={() => {
        Uebersicht.run(`/opt/homebrew/bin/yabai -m space --focus ${index}`);
      }}
    >
      {focused ? "[" : <span>&nbsp;</span>}
      {name}
      {focused ? "]" : <span>&nbsp;</span>}
    </div>
  );
};

const render = ({ output, displays }) => {
  if (typeof output === "undefined") return null;
  const displayId = getCurrentDisplayId(displays);

  // Filter to current display
  let filteredSpaces = output.filter(space => space.display == displayId);

  // Sort by space number
  filteredSpaces = filteredSpaces.sort((a, b) => {
    const aNum = getDisplayNumber(a.label);
    const bNum = getDisplayNumber(b.label);
    if (typeof aNum === 'number' && typeof bNum === 'number') {
      return aNum - bNum;
    }
    return String(a.label).localeCompare(String(b.label));
  });

  let allWindows = filteredSpaces.reduce((agg, space) => agg.concat(space.windows), []);

  let windowsToCount = allWindows.reduce((agg, window) => {
    let windowsOnScreen = agg.hasOwnProperty(window) ? agg[window] : 0;
    agg[window] = windowsOnScreen + 1;
    return agg;
  }, {});

  let windowsOnAllSpaces = Object.keys(windowsToCount)
                                 .filter(window => windowsToCount[window] == filteredSpaces.length)
                                 .map(windowStr => parseInt(windowStr));

  filteredSpaces = filteredSpaces.map(space => {
    space.windows = space.windows.filter(window => !windowsOnAllSpaces.includes(window));
    return space;
  });

  filteredSpaces = filteredSpaces.filter(space => space.windows.length > 0 || space["is-visible"]);

  const spaces = [];

  filteredSpaces.forEach(function (space) {
    spaces.push(renderSpace(space.index, space.label, space["has-focus"], space["is-visible"], space.windows));
  });

  return (
    <div style={containerStyle}>
      {spaces}
    </div>
  );
};

export default render;
