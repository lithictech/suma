import {
  Box,
  Chip,
  Button,
  ButtonGroup,
  Typography,
  Paper,
  Divider,
  Alert,
  Stack,
} from "@mui/material";
import { styled } from "@mui/material/styles";
import React from "react";

const VARIABLES = [
  { id: 1, value: "user.age", label: "age", type: "variable" },
  { id: 2, value: "account.active", label: "active", type: "variable" },
  { id: 3, value: "user.country", label: "country", type: "variable" },
  { id: 4, value: "order.total", label: "total", type: "variable" },
  { id: 5, value: "plan.tier", label: "tier", type: "variable" },
];
const AND = { id: "AND", label: "AND", value: "AND", type: "operator" };
const OR = { id: "OR", label: "OR", value: "OR", type: "operator" };
const OPERATORS = [AND, OR];
const P_OPEN = { id: "(", label: "(", value: "(", type: "paren" };
const P_CLOSE = { id: ")", label: ")", value: ")", type: "paren" };
const PARENS = [P_OPEN, P_CLOSE];

const TOKEN_COLORS = {
  variable: "primary",
  operator: "warning",
  paren: "default",
};

const TOKEN_VARIANTS = {
  variable: "outlined",
  operator: "filled",
  paren: "outlined",
};

function validate(tokens) {
  if (tokens.length === 0) return null;
  let depth = 0;
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    const prev = tokens[i - 1];
    const next = tokens[i + 1];
    if (t.value === "(") {
      depth++;
    } else if (t.value === ")") {
      depth--;
      if (depth < 0) return "Unmatched closing parenthesis";
    }
    if (t.type === "operator") {
      if (!prev || prev.value === "(" || prev.type === "operator")
        return `"${t.value}" cannot appear here`;
      if (!next) return `Expression cannot end with "${t.value}"`;
    }
    if (t.type === "variable") {
      if (prev && (prev.type === "variable" || prev.value === ")"))
        return `Missing operator before "${t.value}"`;
    }
    if (t.value === "(") {
      if (next && next.value === ")") return "Empty parentheses are not allowed";
      if (prev && (prev.type === "variable" || prev.value === ")"))
        return `Missing operator before "("`;
    }
    if (t.value === ")") {
      if (prev && prev.type === "operator") return `Operator before ")" is invalid`;
    }
  }
  if (depth !== 0) return "Unmatched opening parenthesis";
  const last = tokens[tokens.length - 1];
  if (last.type === "operator") return `Expression cannot end with "${last.value}"`;
  return null;
}

// Cursor sits *between* tokens. cursorPos=0 means before all tokens,
// cursorPos=tokens.length means after all tokens.
const CursorLine = styled("span")(({ theme, active }) => ({
  display: "inline-flex",
  alignItems: "center",
  alignSelf: "stretch",
  width: 2,
  minHeight: 24,
  borderRadius: 2,
  backgroundColor: active ? theme.palette.primary.main : "transparent",
  margin: "0 1px",
  transition: "background-color 0.15s",
  cursor: "text",
  flexShrink: 0,
  "&:hover": {
    backgroundColor: theme.palette.primary.light,
  },
}));

// Invisible wider hit-target around each cursor slot
const CursorSlot = styled("span")({
  display: "inline-flex",
  alignItems: "center",
  padding: "0 3px",
  cursor: "text",
  alignSelf: "stretch",
});

const TokenChip = styled(Chip)(({ tokentype }) => ({
  fontFamily: "monospace",
  fontWeight: tokentype === "operator" ? 700 : 400,
  fontSize: tokentype === "paren" ? "1rem" : "0.8rem",
  cursor: "pointer",
  transition: "box-shadow 0.1s",
}));

const PaletteButton = styled(Button)({
  textTransform: "none",
  fontFamily: "monospace",
  fontWeight: 500,
  fontSize: "0.8rem",
});

export default function EligibilityRequirementExpressionEditor({
  expression,
  setExpression,
  sx,
}) {
  const [tokens, setTokens] = React.useState([]);
  // cursorPos: index in [0..tokens.length] — the slot where next insert goes
  const [cursorPos, setCursorPos] = React.useState(0);
  const canvasRef = React.useRef(null);

  // Keep cursor in bounds when tokens shrink
  React.useEffect(() => {
    setCursorPos((p) => Math.min(p, tokens.length));
  }, [tokens.length]);

  const insertToken = React.useCallback(
    (t) => {
      const newToken = { ...t, key: `${t.id}_${Math.random()}` };
      setTokens((prev) => {
        const next = [...prev];
        next.splice(cursorPos, 0, newToken);
        return next;
      });
      setCursorPos((p) => p + 1);
      canvasRef.current?.focus();
    },
    [cursorPos]
  );

  const removeToken = React.useCallback((index) => {
    setTokens((prev) => prev.filter((_, i) => i !== index));
    // Move cursor left if we deleted something before or at cursor
    setCursorPos((p) => (index < p ? p - 1 : p));
  }, []);

  // Delete token immediately before cursor (Backspace behavior)
  const deleteBeforeCursor = React.useCallback(() => {
    if (cursorPos === 0) return;
    removeToken(cursorPos - 1);
  }, [cursorPos, removeToken]);

  const clearAll = () => {
    setTokens([]);
    setCursorPos(0);
  };

  // Keyboard support when canvas is focused
  const handleKeyDown = React.useCallback(
    (e) => {
      if (e.key === "Backspace") {
        e.preventDefault();
        deleteBeforeCursor();
      } else if (e.key === "ArrowLeft") {
        e.preventDefault();
        setCursorPos((p) => Math.max(0, p - 1));
      } else if (e.key === "ArrowRight") {
        e.preventDefault();
        setCursorPos((p) => Math.min(tokens.length, p + 1));
      } else if (e.key === "Home") {
        e.preventDefault();
        setCursorPos(0);
      } else if (e.key === "End") {
        e.preventDefault();
        setCursorPos(tokens.length);
      } else if (e.key === "(") {
        e.preventDefault();
        insertToken(P_OPEN);
      } else if (e.key === ")") {
        e.preventDefault();
        insertToken(P_CLOSE);
      } else if (e.key === "&") {
        e.preventDefault();
        insertToken(AND);
      } else if (e.key === "|") {
        e.preventDefault();
        insertToken(OR);
      } else {
        console.log(e.key, e);
      }
    },
    [deleteBeforeCursor, tokens.length]
  );

  const error = validate(tokens);
  const expressionString = tokens.map((t) => t.value).join(" ");
  const isValid = tokens.length > 0 && !error;

  return (
    <Box sx={sx}>
      <Typography variant="h6" sx={{ mb: 0.5, fontWeight: 600 }}>
        Expression Editor
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
        Members who have attributes that satisfy this requirement gain access to the
        associated resource. Choose a member to check against the expression and see how
        their attributes check out.
      </Typography>
      <Typography variant="body2" color="text.secondary">
        Click a gap between tokens to place your cursor, then pick from the palette to
        insert. Use <HelpChar>← →</HelpChar> to move, <HelpChar>backspace</HelpChar> to
        delete, <HelpChar>&</HelpChar> for AND, <HelpChar>|</HelpChar> for OR,{" "}
        <HelpChar>(</HelpChar> and <HelpChar>)</HelpChar> for parenthesis, or start typing
        a character to auto-complete attribute names.
      </Typography>

      {/* Palette */}
      <Paper variant="outlined" sx={{ p: 2, mt: 1, borderRadius: 2 }}>
        <Stack spacing={1.5}>
          <Box>
            <InputGroupLabel>Variables</InputGroupLabel>
            <Box sx={{ display: "flex", flexWrap: "wrap", gap: 1 }}>
              {VARIABLES.map((v) => (
                <PaletteButton
                  key={v.value}
                  size="small"
                  variant="outlined"
                  color="primary"
                  onClick={() => insertToken(v)}
                >
                  {v.value}
                </PaletteButton>
              ))}
            </Box>
          </Box>

          <Divider />

          <Box sx={{ display: "flex", gap: 2, alignItems: "center", flexWrap: "wrap" }}>
            <Box>
              <InputGroupLabel>Operators</InputGroupLabel>
              <ButtonGroup size="small" variant="outlined" color="warning">
                {OPERATORS.map((op) => (
                  <PaletteButton
                    key={op.id}
                    onClick={() => insertToken(op)}
                    color="warning"
                  >
                    {op.value}
                  </PaletteButton>
                ))}
              </ButtonGroup>
            </Box>
            <Box>
              <InputGroupLabel>Parentheses</InputGroupLabel>
              <ButtonGroup size="small" variant="outlined">
                {PARENS.map((p) => (
                  <PaletteButton
                    key={p.id}
                    onClick={() => insertToken(p)}
                    sx={{ fontSize: "1rem", px: 1.5 }}
                  >
                    {p.value}
                  </PaletteButton>
                ))}
              </ButtonGroup>
            </Box>
          </Box>
        </Stack>
      </Paper>

      {/* Expression canvas */}
      <Paper
        ref={canvasRef}
        variant="outlined"
        tabIndex={0}
        onKeyDown={handleKeyDown}
        onClick={() => {
          // clicking blank space in the canvas moves cursor to end
          setCursorPos(tokens.length);
          canvasRef.current?.focus();
        }}
        sx={{
          p: 2,
          mt: 1,
          mb: 1,
          borderRadius: 2,
          minHeight: 64,
          borderColor: error ? "error.main" : isValid ? "success.main" : "divider",
          transition: "border-color 0.2s",
          backgroundColor: "background.default",
          outline: "none",
          cursor: "text",
          "&:focus": {
            boxShadow: (theme) => `0 0 0 2px ${theme.palette.primary.main}33`,
          },
        }}
      >
        {tokens.length === 0 ? (
          // Empty state: show a cursor + placeholder text
          <Box sx={{ display: "flex", alignItems: "center", minHeight: 32 }}>
            <CursorSlot
              onClick={(e) => {
                e.stopPropagation();
                setCursorPos(0);
                canvasRef.current?.focus();
              }}
            >
              <CursorLine active={1} />
            </CursorSlot>
            <Typography
              variant="body2"
              color="text.disabled"
              sx={{ fontStyle: "italic" }}
            >
              Click here, then choose tokens above…
            </Typography>
          </Box>
        ) : (
          <Box
            sx={{
              display: "flex",
              flexWrap: "wrap",
              gap: 0.5,
              alignItems: "center",
              minHeight: 32,
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Slot BEFORE index 0 */}
            <CursorSlot
              onClick={() => {
                setCursorPos(0);
                canvasRef.current?.focus();
              }}
            >
              <CursorLine active={cursorPos === 0 ? 1 : 0} />
            </CursorSlot>

            {tokens.map((t, i) => (
              <Box key={t.key} sx={{ display: "contents" }}>
                <TokenChip
                  label={t.value}
                  tokentype={t.type}
                  color={TOKEN_COLORS[t.type]}
                  size="small"
                  onDelete={(e) => {
                    e.stopPropagation();
                    removeToken(i);
                  }}
                  variant={TOKEN_VARIANTS[t.type]}
                  onClick={(e) => {
                    // clicking a token moves cursor to its right side
                    e.stopPropagation();
                    setCursorPos(i + 1);
                    canvasRef.current?.focus();
                  }}
                />
                {/* Slot AFTER token i */}
                <CursorSlot
                  onClick={(e) => {
                    e.stopPropagation();
                    setCursorPos(i + 1);
                    canvasRef.current?.focus();
                  }}
                >
                  <CursorLine active={cursorPos === i + 1 ? 1 : 0} />
                </CursorSlot>
              </Box>
            ))}
          </Box>
        )}
      </Paper>

      {/* Validation feedback */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Output & actions */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
          flexWrap: "wrap",
          gap: 1,
        }}
      >
        <Box sx={{ flex: 1 }}>
          <Typography
            variant="caption"
            color="text.secondary"
            sx={{ fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}
          >
            Output string
          </Typography>
          <Typography
            variant="body2"
            sx={{
              fontFamily: "monospace",
              color: tokens.length ? "text.primary" : "text.disabled",
              wordBreak: "break-all",
            }}
          >
            {expressionString || "—"}
          </Typography>
        </Box>
        <Button
          size="small"
          variant="text"
          color="error"
          onClick={clearAll}
          disabled={tokens.length === 0}
        >
          Clear all
        </Button>
      </Box>
    </Box>
  );
}

function HelpChar({ children }) {
  return <strong style={{ fontFamily: "monospace" }}>{children}</strong>;
}

function InputGroupLabel({ children }) {
  return (
    <Typography
      variant="caption"
      color="text.secondary"
      sx={{
        mb: 0.75,
        display: "block",
        fontWeight: 600,
        textTransform: "uppercase",
        letterSpacing: "0.05em",
      }}
    >
      {children}
    </Typography>
  );
}
