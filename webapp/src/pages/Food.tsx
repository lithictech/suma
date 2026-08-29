import TODO from "../components/TODO.tsx";

export default function Food() {
  return <TODO />;
}
//   const {
//     state: offerings,
//     loading: offeringsLoading,
//     error: offeringsError,
//   } = useAsyncFetch<{ items: Offering[] }>(api.getCommerceOfferings, {
//     pickData: true,
//   });
//   if (offeringsError) {
//     return (
//       <LayoutContainer top>
//         <ErrorScreen />
//       </LayoutContainer>
//     );
//   }
//   if (offeringsLoading) {
//     return (
//       <TODO>
//         <PageLoader buffered />
//       </TODO>
//     );
//   }
//   const { items } = offerings;
//   if (isEmpty(items)) {
//     return (
//       <TODO>
//         <WaitingList title={t("food.title")} text={t("food.intro")} survey={surveySpec} />
//         <OrderHistoryLink />
//       </TODO>
//     );
//   }
//   return (
//     <Page appNav>
//       <PageHeader title={t("food.current_offerings")} subtitle="Lorem ipsum dolor est." />
//       <Stack gap={3}>
//         {items.map((it) => (
//           <OfferingCard key={it.id} {...it} />
//         ))}
//       </Stack>
//       <OrderHistoryLink />
//     </Page>
//   );
// }
//
// function OfferingCard({ description, image, closesAt, appLink }: Offering) {
//   return (
//     <Card className="w-100">
//       <CardBody>
//         <Stack col gap={3}>
//           <CardImage>
//             <Link to={appLink as RoutePath}>
//               <SumaImage image={image} width={300} height={120} cover />
//             </Link>
//           </CardImage>
//           {closesAt && (
//             <p className="color-text-muted font-size-sm">
//               {t("food.available_until", { date: dayjs(closesAt).format("ll") })}
//             </p>
//           )}
//           <Link to={appLink as RoutePath}>
//             <p className="font-weight-bold font-size-lg">{description}</p>
//           </Link>
//           <Button to={appLink as RoutePath} variant="text">
//             <Stack row center className="justify-content-between">
//               <p className="color-text-muted font-size-sm">View products</p>
//               <Icon icon={ChevronRightIcon} />
//             </Stack>
//           </Button>
//         </Stack>
//       </CardBody>
//     </Card>
//   );
// }
//
// function OrderHistoryLink() {
//   const { user } = useUser();
//   if (!user.hasOrderHistory) {
//     return null;
//   }
//   return (
//     <>
//       <hr className="my-4" />
//       <LayoutContainer gutters>
//         <div className="button-stack">
//           <Button variant="outline" to="/order-history">
//             <i className="bi bi-bag-check-fill me-2"></i>
//             {t("food.order_history_title")}
//           </Button>
//         </div>
//       </LayoutContainer>
//     </>
//   );
// }
//
// const surveySpec = {
//   topic: "food_waitlist",
//   questions: [
//     {
//       key: "entity_type",
//       labelKey: "surveys.member_type.label",
//       format: "radio" as const,
//       answers: [
//         { key: "community", labelKey: "surveys.member_type.community" },
//         { key: "for_profit", labelKey: "surveys.member_type.for_profit" },
//         { key: "government", labelKey: "surveys.member_type.government" },
//         { key: "non_profit", labelKey: "surveys.member_type.non_profit" },
//         { key: "philanthropy", labelKey: "surveys.member_type.philanthropy" },
//       ],
//     },
//     {
//       key: "food_shopping",
//       labelKey: "surveys.food_options.label",
//       format: "checkbox" as const,
//       answers: [
//         { key: "albertsons", labelKey: "surveys.food_options.albertsons" },
//         { key: "fred_meyer", labelKey: "surveys.food_options.fred_meyer" },
//         { key: "safeway", labelKey: "surveys.food_options.safeway" },
//         { key: "winco", labelKey: "surveys.food_options.winco" },
//         { key: "market", labelKey: "surveys.food_options.market" },
//       ],
//     },
//     {
//       key: "learn_more",
//       labelKey: "surveys.food_learn_more.label",
//       format: "checkbox" as const,
//       answers: [
//         {
//           key: "connect_resources",
//           labelKey: "surveys.food_learn_more.connect_resources",
//         },
//         {
//           key: "grant_support",
//           labelKey: "surveys.food_learn_more.grant_support",
//         },
//         { key: "partner", labelKey: "surveys.food_learn_more.partner" },
//         { key: "save", labelKey: "surveys.food_learn_more.save" },
//       ],
//     },
//   ],
// };
