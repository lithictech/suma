import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import RLink from "./RLink";
import SumaImage from "./SumaImage";
import clsx from "clsx";
import React from "react";
import Card from "react-bootstrap/Card";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function VendibleCard({ name, image, until, link, className }) {
  return (
    <Card className={clsx(className)}>
      <Card.Body className="p-2">
        <Stack direction="horizontal" gap={3}>
          <Link to={link} className="flex-shrink-0">
            <SumaImage image={image} width={100} h={80} alt={name} />
          </Link>
          <div>
            <Card.Link
              as={RLink}
              href={link}
              state={{ fromIndex: true }}
              className="h6 mb-0"
            >
              {name}
            </Card.Link>
            <Card.Text className="text-secondary small">
              {t("food:available_until", { date: dayjs(until).format("ll") })}
            </Card.Text>
          </div>
        </Stack>
      </Card.Body>
    </Card>
  );
}
