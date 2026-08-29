import { t } from "../../localization";
import { MdLink } from "../SumaMarkdown";

export default function DrawerContentsIntro() {
  return t(
    "mobility.intro",
    {},
    {
      markdown: {
        overrides: {
          a: { component: MdLink },
          p: {
            props: {
              className: "text-secondary",
            },
          },
        },
      },
    }
  );
}
