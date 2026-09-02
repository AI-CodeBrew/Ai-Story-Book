import { notFound } from "next/navigation";
import { getStory } from "@/lib/api";
import { StoryViewerClient } from "./StoryViewerClient";

export default async function StoryPage({ params }: PageProps<"/story/[id]">) {
  const { id } = await params;

  const story = await getStory(id).catch(() => null);
  if (!story) notFound();

  return <StoryViewerClient story={story} />;
}
