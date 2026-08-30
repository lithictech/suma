import ErrorPage from "../components/ErrorPage.tsx";
import LoadingPage from "../components/LoadingPage.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Pages",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const ErrorPageBack: Story = {
  render: () => (
    <DemoStack>
      <ErrorPage variant="back" page={true} />
    </DemoStack>
  ),
};

export const ErrorPageHome: Story = {
  render: () => (
    <DemoStack>
      <ErrorPage variant="home" page={true} />
    </DemoStack>
  ),
};

export const ErrorPageHeader: Story = {
  render: () => (
    <DemoStack>
      <ErrorPage
        variant="home"
        page={true}
        header={<PageHeader title="Some title" subtitle="Some subtitle" />}
      />
    </DemoStack>
  ),
};

export const ErrorPageEmbedded: Story = {
  render: () => (
    <DemoStack>
      <Page>
        <PageHeader title="This is outside ErrorPage" />
        <ErrorPage variant="home" page={false} />
      </Page>
    </DemoStack>
  ),
};

export const LoadingPageSimple: Story = {
  render: () => (
    <DemoStack>
      <LoadingPage page={true} />
    </DemoStack>
  ),
};

export const LoadingPageHeader: Story = {
  render: () => (
    <DemoStack>
      <LoadingPage
        page={true}
        header={<PageHeader title="Some title" subtitle="Some subtitle" />}
      />
    </DemoStack>
  ),
};

export const LoadingPageEmbedded: Story = {
  render: () => (
    <DemoStack>
      <Page>
        <PageHeader title="This is outside LoadingPage" />
        <LoadingPage page={false} />
      </Page>
    </DemoStack>
  ),
};
