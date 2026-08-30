import todo from "../modules/todo.ts";

export interface TODOProps {
  children?: any;
  [rest: string]: any;
}

export default function TODO({ children, ...rest }: TODOProps) {
  todo(rest);
  return (
    <div>
      <h1>TODO</h1>
      {children}
    </div>
  );
}
