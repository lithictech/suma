import PrivacyPolicy from "../components/PrivacyPolicy.tsx";

export default function PrivacyPolicyPage({ contentOnly }: { contentOnly?: boolean }) {
  return <PrivacyPolicy contentOnly={contentOnly} />;
}
