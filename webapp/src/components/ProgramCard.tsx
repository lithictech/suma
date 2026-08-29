import { dt, t } from "../localization";
import { dayjs } from "../modules/dayConfig.ts";
import { untypedRoutePath } from "../routing/RoutePath.ts";
import Button from "../ui/Button.tsx";
import Card from "../ui/Card.tsx";
import CardBody from "../ui/CardBody.tsx";
import Icon from "../ui/Icon.tsx";
import "./ProgramCard.css";
import SumaImage from "./SumaImage.tsx";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import { Link } from "react-router-dom";

export default function ProgramCard({
  name,
  description,
  image,
  periodEnd,
  appLink,
  appLinkText,
}: Program) {
  const ImageComp = appLink ? Link : "div";
  return (
    <Card>
      <CardBody>
        {/*<HeaderLink to={appLink}>*/}
        {/*  <h5*/}
        {/*    className="border border-2 border-dark rounded-2 bg-white py-2 px-3 position-absolute program-card-title"*/}
        {/*    style={{ zIndex: 1 }}*/}
        {/*  >*/}
        {/*    {name}*/}
        {/*  </h5>*/}
        {/*</HeaderLink>*/}
        <ImageComp
          to={appLink}
          // className="flex-shrink-0 overflow-hidden position-relative"
        >
          <SumaImage
            image={image}
            w={500}
            height={200}
            params={{ crop: "entropy", resize: "fill" }}
            style={{ maxWidth: "100%", objectFit: "cover" }}
            className="border-radius"
          />
        </ImageComp>
        {periodEnd && (
          <p className="font-size-sm mt-2">
            {t("dashboard.program_ends", { date: dayjs(periodEnd).format("ll") })}
          </p>
        )}
        <h2 className="mt-2">{name}</h2>
        <div className="mt-2">{dt(description)}</div>
        {appLink && (
          <Button
            to={untypedRoutePath(appLink)}
            variant="text"
            size="sm"
            className="mt-2 program-card-goto"
          >
            {appLinkText} <Icon icon={ChevronRightIcon} />
          </Button>
        )}
      </CardBody>
    </Card>
  );
}
