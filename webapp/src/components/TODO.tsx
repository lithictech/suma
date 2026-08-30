import todo from "../modules/todo.ts";

export interface TODOProps {
  children?: any;
  [rest: string]: any;
}

export default function TODO({ ...rest }: TODOProps) {
  todo(rest);
  return (
    <div>
      <h1>TODO</h1>
    </div>
  );
}
