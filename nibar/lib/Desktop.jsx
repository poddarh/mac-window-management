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

// Check if a space belongs to the active workspace or is a shared space
const isSpaceVisible = (label, activeWorkspace) => {
  if (!label || label === "") {
    // Unlabeled spaces are visible
    return true;
  }

  // Shared spaces (space_07 through space_10)
  if (/^space_0[7-9]$/.test(label) || label === "space_10") {
    return true;
  }

  // Workspace-specific spaces (activeWorkspace_01 through activeWorkspace_06)
  const workspacePattern = new RegExp(`^${activeWorkspace}_0[1-6]$`);
  if (workspacePattern.test(label)) {
    return true;
  }

  return false;
};

// Get display number for a space label
const getDisplayNumber = (label, activeWorkspace) => {
  if (!label || label === "") {
    return label;
  }

  // Shared spaces: space_07 -> 7, space_10 -> 10
  if (/^space_0[7-9]$/.test(label)) {
    return parseInt(label.substr(6));
  }
  if (label === "space_10") {
    return 10;
  }

  // Workspace-specific spaces: {workspace}_01 -> 1
  const workspacePattern = new RegExp(`^${activeWorkspace}_0([1-6])$`);
  const match = label.match(workspacePattern);
  if (match) {
    return parseInt(match[1]);
  }

  return label;
};

const renderSpace = (index, label, focused, visible, windows, activeWorkspace) => {
  let contentStyle = JSON.parse(JSON.stringify(desktopStyle));

  let hasWindows = windows.length > 0;

  let name = getDisplayNumber(label, activeWorkspace);
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

const render = ({ output, displays, activeWorkspace }) => {
  if (typeof output === "undefined") return null;
  const displayId = getCurrentDisplayId(displays);

  // Filter to current display
  let filteredSpaces = output.filter(space => space.display == displayId);

  // Filter by active workspace
  filteredSpaces = filteredSpaces.filter(space =>
    isSpaceVisible(space.label, activeWorkspace)
  );

  // Sort spaces: workspace-specific (1-6) first, then shared (7-10)
  filteredSpaces = filteredSpaces.sort((a, b) => {
    const aNum = getDisplayNumber(a.label, activeWorkspace);
    const bNum = getDisplayNumber(b.label, activeWorkspace);
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
    spaces.push(renderSpace(space.index, space.label, space["has-focus"], space["is-visible"], space.windows, activeWorkspace));
  });

  return (
    <div style={containerStyle}>
      {spaces}
    </div>
  );
};

export default render;
