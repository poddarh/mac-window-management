import * as Uebersicht from 'uebersicht'
import parse from "./lib/parse.jsx";
import Error from "./lib/Error.jsx";
import styles from "./lib/styles.jsx";

const { React } = Uebersicht;
const { useState, useEffect } = React;

const containerStyle = {
  padding: "0 8px",
  display: "grid",
  gridAutoFlow: "column",
  gridGap: "8px",
  position: "fixed",
  overflow: "hidden",
  left: "50%",
  transform: "translateX(-50%)",
  bottom: "0px",
  fontFamily: styles.fontFamily,
  lineHeight: styles.lineHeight,
  fontSize: styles.fontSize,
  color: styles.colors.dim,
  fontWeight: styles.fontWeight
};

const workspaceStyle = {
  cursor: "pointer",
  userSelect: "none"
};

const addButtonStyle = {
  cursor: "pointer",
  userSelect: "none",
  color: styles.colors.dim
};

const inputStyle = {
  background: "transparent",
  border: "none",
  borderBottom: `1px solid ${styles.colors.accent}`,
  color: styles.colors.fg,
  fontFamily: styles.fontFamily,
  fontSize: styles.fontSize,
  outline: "none",
  width: "80px",
  padding: "0"
};

const deleteButtonStyle = {
  cursor: "pointer",
  color: styles.colors.dim,
  marginLeft: "4px",
  fontSize: "12px"
};

// Workspace widget component
const WorkspaceSwitcher = ({ activeWorkspace, workspaces }) => {
  const [mode, setMode] = useState('normal'); // 'normal', 'create', 'rename', 'delete'
  const [inputValue, setInputValue] = useState('');
  const [targetWorkspace, setTargetWorkspace] = useState('');

  // Reset mode when activeWorkspace changes
  useEffect(() => {
    setMode('normal');
    setInputValue('');
    setTargetWorkspace('');
  }, [activeWorkspace]);

  const switchToWorkspace = (name) => {
    if (mode !== 'normal') return;
    if (name !== activeWorkspace) {
      Uebersicht.run(`$HOME/.yabai/workspaces.sh switch "${name}"`);
    }
  };

  const createWorkspace = (name) => {
    if (name && name.trim()) {
      Uebersicht.run(`$HOME/.yabai/workspaces.sh create "${name.trim()}"`);
    }
    setMode('normal');
    setInputValue('');
  };

  const renameWorkspace = (oldName, newName) => {
    if (newName && newName.trim() && newName.trim() !== oldName) {
      Uebersicht.run(`$HOME/.yabai/workspaces.sh rename "${oldName}" "${newName.trim()}"`);
    }
    setMode('normal');
    setInputValue('');
    setTargetWorkspace('');
  };

  const deleteWorkspace = (name) => {
    Uebersicht.run(`$HOME/.yabai/workspaces.sh delete "${name}"`);
    setMode('normal');
    setTargetWorkspace('');
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      if (mode === 'create') {
        createWorkspace(inputValue);
      } else if (mode === 'rename') {
        renameWorkspace(targetWorkspace, inputValue);
      }
    }
  };

  const handleDoubleClick = (e, name) => {
    e.stopPropagation();
    setMode('rename');
    setTargetWorkspace(name);
    setInputValue(name);
  };

  const handleRightClick = (e, name) => {
    e.preventDefault();
    setMode('delete');
    setTargetWorkspace(name);
  };

  const handleAddClick = (e) => {
    e.stopPropagation();
    if (mode === 'create') {
      // Clicking [+] again cancels create mode
      setMode('normal');
      setInputValue('');
    } else {
      setMode('create');
      setInputValue('');
    }
  };

  // Render a single workspace
  const renderWorkspace = (name, isActive) => {
    const style = {
      ...workspaceStyle,
      color: isActive ? styles.colors.accent : styles.colors.dim,
      fontWeight: isActive ? "700" : styles.fontWeight
    };

    // If in rename mode for this workspace
    if (mode === 'rename' && targetWorkspace === name) {
      return (
        <span key={name} style={{display: 'flex', alignItems: 'center'}}>
          <input
            type="text"
            style={inputStyle}
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
          />
          <span
            style={{...deleteButtonStyle, marginLeft: '4px'}}
            onClick={() => { setMode('normal'); setInputValue(''); setTargetWorkspace(''); }}
            title="Cancel"
          >
            [x]
          </span>
        </span>
      );
    }

    return (
      <span
        key={name}
        style={style}
        onClick={() => switchToWorkspace(name)}
        onDoubleClick={(e) => handleDoubleClick(e, name)}
        onContextMenu={(e) => handleRightClick(e, name)}
        title="Click: switch | Double-click: rename | Right-click: delete"
      >
        {isActive ? "[" : <span>&nbsp;</span>}
        {name}
        {isActive ? "]" : <span>&nbsp;</span>}
      </span>
    );
  };

  // Render delete confirmation
  if (mode === 'delete') {
    return (
      <div style={containerStyle}>
        <span style={{color: styles.colors.dim}}>delete {targetWorkspace}?</span>
        <span
          style={{...workspaceStyle, color: styles.colors.accent, fontWeight: '700'}}
          onClick={() => deleteWorkspace(targetWorkspace)}
        >
          [yes]
        </span>
        <span
          style={{...workspaceStyle, color: styles.colors.dim}}
          onClick={() => { setMode('normal'); setTargetWorkspace(''); }}
        >
          [no]
        </span>
      </div>
    );
  }

  // Render create input
  if (mode === 'create') {
    return (
      <div style={containerStyle}>
        {workspaces.map(name => renderWorkspace(name, name === activeWorkspace))}
        <input
          type="text"
          style={inputStyle}
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="new..."
          autoFocus
        />
        <span
          style={addButtonStyle}
          onClick={handleAddClick}
          title="Cancel"
        >
          [x]
        </span>
      </div>
    );
  }

  // Normal mode (and rename/delete modes handled per-workspace)
  return (
    <div style={containerStyle}>
      {workspaces.map(name => renderWorkspace(name, name === activeWorkspace))}
      <span
        style={addButtonStyle}
        onClick={handleAddClick}
        title="Create new workspace"
      >
        [+]
      </span>
    </div>
  );
};

export const refreshFrequency = false;
export const command = "./nibar/scripts/workspaces.sh";

export const render = ({ output }) => {
  const data = parse(output);

  if (typeof data === "undefined") {
    return (
      <div style={containerStyle}>
        <Error msg="Error: unknown script output" side="center" />
      </div>
    );
  }

  const activeWorkspace = data.activeWorkspace || "default";
  const workspaces = data.workspaces || ["default"];

  return (
    <WorkspaceSwitcher
      activeWorkspace={activeWorkspace}
      workspaces={workspaces}
    />
  );
};

export default null;
