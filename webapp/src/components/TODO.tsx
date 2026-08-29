export interface TODOProps {
  children?: any;
  [rest: string]: any;
}

export default function TODO({ children, ...rest }: TODOProps) {
  console.log("TODO:", rest);
  return (
    <div>
      <h1>TODO</h1>
      {children}
    </div>
  );
}
