import styles from "./styles.jsx";
import * as Uebersicht from 'uebersicht'

const containerStyle = {
  display: "grid",
  gridAutoFlow: "column",
  gridGap: "8px"
};

const desktopStyle = {
  // width: '4ch',
};

// Note that this can change at any time
const getCurrentDisplayId = (displays) => {
  let displayIndex = window.location.pathname.split('/')[1];
  let display = displays.filter(display => display.id == displayIndex)[0];
  return display.index;
}

const renderSpace = (index, label, focused, visible, windows) => {
  let contentStyle = JSON.parse(JSON.stringify(desktopStyle));

  let hasWindows = windows.length > 0;

  let name = "i" + index;
  if (label !== undefined && label.startsWith("space_")) {
    name = "" + parseInt(label.substr(6));
  }

  if (focused) {
    contentStyle.color = styles.colors.fg;
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

  output = output.sort((a, b) => a.label.localeCompare(b.label));
  output = output.filter(space => space.display == displayId);

  let allWindows = output.reduce((agg, space) => agg.concat(space.windows), []);

  let windowsToCount = allWindows.reduce((agg, window) => {
    let windowsOnScreen = agg.hasOwnProperty(window) ? agg[window] : 0;
    agg[window] = windowsOnScreen + 1;
    return agg;
  }, {});

  let windowsOnAllSpaces = Object.keys(windowsToCount)
                                 .filter(window => windowsToCount[window] == output.length)
                                 .map(windowStr => parseInt(windowStr));

  output = output.map(space => {
    space.windows = space.windows.filter(window => !windowsOnAllSpaces.includes(window));
    return space;
  });

  output = output.filter(space => space.windows.length > 0 || space["is-visible"]);

  const spaces = [];

  output.forEach(function (space) {
    spaces.push(renderSpace(space.index, space.label, space["has-focus"], space["is-visible"], space.windows));
  });

  return (
    <div style={containerStyle}>
      {spaces}
    </div>
  );
};

export default render;
