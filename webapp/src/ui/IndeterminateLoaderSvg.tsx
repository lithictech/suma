export default function IndeterminantLoaderSvg({ size }: { size?: number }) {
  size = size || 300;
  return (
    <svg
      style={{
        margin: "auto",
        background: "none",
        display: "block",
        shapeRendering: "auto",
      }}
      width={size}
      height={size}
      viewBox="31 31 38 38"
      preserveAspectRatio="xMidYMid"
    >
      <defs>
        <radialGradient
          id="ldio-4tvqiefh3c8-gradient"
          cx="0.5"
          cy="0.5"
          fx="0"
          fy="0"
          r="2"
        >
          <stop offset="0%" style={{ stopColor: "var(--tint-primary)" }}></stop>
          <stop offset="100%" style={{ stopColor: "var(--color-accent)" }}></stop>
        </radialGradient>
      </defs>
      <g>
        <circle
          cx="50"
          cy="50"
          r="16"
          stroke="url(#ldio-4tvqiefh3c8-gradient)"
          strokeWidth="3"
          fill="none"
        ></circle>
        <animateTransform
          attributeName="transform"
          type="rotate"
          values="0 50 50;360 50 50"
          dur="0.9"
          repeatCount="indefinite"
        ></animateTransform>
      </g>
    </svg>
  );
}
