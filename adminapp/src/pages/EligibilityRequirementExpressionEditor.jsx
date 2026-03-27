import api from "../api";
import AdminLink from "../components/AdminLink";
import useDebounced from "../hooks/useDebounced";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
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
  CircularProgress,
  Table,
  TableContainer,
  TableHead,
  TableRow,
  TableBody,
} from "@mui/material";
import TableCell from "@mui/material/TableCell";
import { styled } from "@mui/material/styles";
import { useTheme } from "@mui/styles";
import React from "react";

export default function EligibilityRequirementExpressionEditor({
  requirement,
  expressionTokens,
  setExpression,
  sx,
}) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const [error, setError] = React.useState("");
  const [tokens, setTokens] = React.useState(expressionTokens);
  const [evaluationResult, setEvaluationResult] = React.useState(null);

  const canvasRef = React.useRef(null);
  // cursorPos: index in [0..tokens.length] — the slot where next insert goes
  const [cursorPos, setCursorPosInner] = React.useState(0);
  const setCursorPos = React.useCallback((v) => {
    setCursorPosInner(v);
    canvasRef.current?.focus();
  }, []);

  const { state: editorSettings, loading: editorSettingsLoading } = useAsyncFetch(
    api.eligibilityRequirementExpressionEditorSettings,
    { pickData: true }
  );

  const detokenize = useDebounced(
    api.eligibilityRequirementExpressionEditorDetokenize,
    (r) => {
      const d = r.data;
      setError(d.warnings.length > 0 ? d.warnings[0].string : "");
      setExpression(d.serialized);
      return api
        .eligibilityRequirementExpressionEditorEvaluate({
          requirementId: requirement.id,
          serializedExpression: d.serialized,
        })
        .then((r) => {
          setEvaluationResult(r.data);
        });
    },
    enqueueErrorSnackbar,
    { wait: 1, maxWait: 10 }
  );

  // Whenever the tokens change, parse it as an expression.
  React.useEffect(() => {
    detokenize({ tokens });
    // We can use setExpression with whatever is the latest version given the token update.
    // Using setExpression as a dep causes this effect to fire itself circularly.
    // We cannot easily do this by wrapping the setState either; this is good enough.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enqueueErrorSnackbar, tokens]);

  // Keep cursor in bounds when tokens shrink
  React.useEffect(() => {
    setCursorPos((p) => Math.min(p, tokens.length));
  }, [setCursorPos, tokens.length]);

  const insertToken = React.useCallback(
    (t) => {
      setTokens((prev) => {
        const next = [...prev];
        next.splice(cursorPos, 0, t);
        return next;
      });
      setCursorPos((p) => p + 1);
    },
    [cursorPos, setCursorPos]
  );

  const removeToken = React.useCallback(
    (index) => {
      setTokens((prev) => prev.filter((_, i) => i !== index));
      // Move cursor left if we deleted something before or at cursor
      setCursorPos((p) => (index < p ? p - 1 : p));
    },
    [setCursorPos]
  );

  // Delete token immediately before cursor (Backspace behavior)
  const deleteBeforeCursor = React.useCallback(() => {
    if (cursorPos === 0) {
      return;
    }
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
        insertToken(editorSettings.parenOpen);
      } else if (e.key === ")") {
        e.preventDefault();
        insertToken(editorSettings.parenClose);
      } else if (e.key === "&") {
        e.preventDefault();
        insertToken(editorSettings.opAnd);
      } else if (e.key === "|") {
        e.preventDefault();
        insertToken(editorSettings.opOr);
      } else {
        // console.log(e.key, e);
      }
    },
    [deleteBeforeCursor, editorSettings, insertToken, setCursorPos, tokens.length]
  );

  const isValid = tokens.length > 0 && !error;

  if (editorSettingsLoading) {
    return <CircularProgress />;
  }

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
        <HelpChar>(</HelpChar> and <HelpChar>)</HelpChar> for parenthesis, or choose
        attribute names from the list.
      </Typography>

      {/* Palette */}
      <Paper variant="outlined" sx={{ p: 2, mt: 1, borderRadius: 2 }}>
        <Stack spacing={1.5}>
          <Box>
            <InputGroupLabel>Variables</InputGroupLabel>
            <Box sx={{ display: "flex", flexWrap: "wrap", gap: 1 }}>
              {editorSettings.attributes.map((t) => (
                <PaletteButton
                  key={t.id}
                  size="small"
                  variant="outlined"
                  color={TOKEN_COLORS[t.type]}
                  onClick={() => insertToken(t)}
                >
                  {t.value}
                </PaletteButton>
              ))}
            </Box>
          </Box>

          <Divider />

          <Box sx={{ display: "flex", gap: 2, alignItems: "center", flexWrap: "wrap" }}>
            <Box>
              <InputGroupLabel>Operators</InputGroupLabel>
              <ButtonGroup size="small" variant="outlined" color="warning">
                {editorSettings.ops.map((t) => (
                  <PaletteButton
                    key={t.id}
                    color={TOKEN_COLORS[t.type]}
                    onClick={() => insertToken(t)}
                  >
                    {t.value}
                  </PaletteButton>
                ))}
              </ButtonGroup>
            </Box>
            <Box>
              <InputGroupLabel>Parentheses</InputGroupLabel>
              <ButtonGroup size="small" variant="outlined">
                {editorSettings.parens.map((t) => (
                  <PaletteButton
                    key={t.id}
                    color={TOKEN_COLORS[t.type]}
                    onClick={() => insertToken(t)}
                    sx={{ fontSize: "1rem", px: 1.5 }}
                  >
                    {t.value}
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
              gap: 0.25,
              alignItems: "center",
              minHeight: 32,
              cursor: "text",
            }}
            onClick={(e) => {
              e.stopPropagation();
              setCursorPos(tokens.length);
            }}
          >
            {/* Slot BEFORE index 0 */}
            <CursorSlot
              onClick={() => {
                setCursorPos(0);
              }}
            >
              <CursorLine active={cursorPos === 0 ? 1 : 0} />
            </CursorSlot>

            {tokens.map((t, i) => (
              <Box key={`${t.id}${i}`} sx={{ display: "contents" }}>
                <TokenChip
                  label={t.value}
                  tokentype={t.type}
                  color={TOKEN_COLORS[t.type]}
                  size="small"
                  onDelete={(e) => {
                    e.stopPropagation();
                    removeToken(i);
                  }}
                  variant={TOKEN_CHIP_VARIANTS[t.type]}
                  onClick={(e) => {
                    // clicking a token moves cursor to its right side
                    e.stopPropagation();
                    setCursorPos(i + 1);
                  }}
                />
                {/* Slot AFTER token i */}
                <CursorSlot
                  onClick={(e) => {
                    e.stopPropagation();
                    setCursorPos(i + 1);
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
      <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            flexWrap: "wrap",
            gap: 1,
          }}
        >
          <ExpressionString tokens={tokens} />
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
        <EvaluationResult requirement={requirement} evaluationResult={evaluationResult} />
      </Box>
    </Box>
  );
}

const TOKEN_COLORS = {
  variable: "primary",
  operator: "warning",
  paren: "secondary",
};

const TOKEN_CHIP_VARIANTS = {
  variable: "filled",
  operator: "outlined",
  paren: "outlined",
};

const TOKEN_WEIGHTS = {
  variable: 400,
  operator: 400,
  paren: 700,
};

function ExpressionString({ tokens }) {
  const theme = useTheme();

  const inner = (() => {
    if (tokens.length === 0) {
      return "-";
    }

    const els = tokens.map((t, i) => {
      const key = `${t.id}-${i}`;
      let color = theme.palette[TOKEN_COLORS[t.type]].main;
      let fontWeight = TOKEN_WEIGHTS[t.type];
      let v = t.value;
      if (t.type === "variable") {
        console.log();
      } else if (t.type === "paren") {
        console.log();
      } else {
        v = ` ${v} `;
      }
      return (
        <span key={key} style={{ color, fontWeight }}>
          {v}
        </span>
      );
    });
    return els;
  })();
  return (
    <Box sx={{ flex: 1 }}>
      <Typography
        variant="caption"
        color="text.secondary"
        sx={{ fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}
      >
        Expression
      </Typography>
      <Typography
        variant="body2"
        sx={{
          fontFamily: "monospace",
          color: tokens.length ? "text.primary" : "text.disabled",
          wordBreak: "break-all",
        }}
      >
        {inner}
      </Typography>
    </Box>
  );
}

function EvaluationResult({ requirement, evaluationResult }) {
  const r = evaluationResult;
  if (!r) {
    return null;
  }
  return (
    <TableContainer>
      <Typography
        variant="caption"
        color="text.secondary"
        sx={{ fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}
      >
        Evaluation
      </Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Member</TableCell>
            <TableCell>
              <AdminLink model={r.member}>{r.member.name}</AdminLink>
            </TableCell>
          </TableRow>
        </TableHead>
      </Table>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Expression</TableCell>
            <TableCell>Passed</TableCell>
            <TableCell>Requirement</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {r.expressions.map(
            ({
              requirementId,
              requirementAdminLink,
              requirementLabel,
              formula,
              passed,
            }) => (
              <TableRow key={requirementAdminLink}>
                <TableCell>{formula}</TableCell>
                <TableCell>{passed ? "✅" : "❌"}</TableCell>
                <TableCell>
                  <AdminLink to={requirementAdminLink}>
                    {requirementLabel}
                    {requirementId === requirement.id ? " (this)" : ""}
                  </AdminLink>
                </TableCell>
              </TableRow>
            )
          )}
        </TableBody>
      </Table>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Attribute Assignments</TableCell>
            <TableCell>Depth</TableCell>
            <TableCell colSpan={2}>Source</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {r.assignments.map(
            ({
              attributeAdminLink,
              label,
              depth,
              sourceType,
              sourceLabels,
              sourceAdminLinks,
            }) => (
              <TableRow key={label}>
                <TableCell>
                  <AdminLink to={attributeAdminLink}>{label}</AdminLink>
                </TableCell>
                <TableCell>{depth}</TableCell>
                <TableCell>{sourceType}</TableCell>
                <TableCell>
                  {sourceLabels.map((lbl, i) => (
                    <React.Fragment key={lbl}>
                      <AdminLink to={sourceAdminLinks[i]}>{lbl}</AdminLink>
                      <br />
                    </React.Fragment>
                  ))}
                </TableCell>
              </TableRow>
            )
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
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
  padding: "2px 1px",
  cursor: "text",
  alignSelf: "stretch",
});

const TokenChip = styled(Chip)(({ tokentype }) => ({
  fontFamily: "monospace",
  fontWeight: TOKEN_WEIGHTS[tokentype],
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
