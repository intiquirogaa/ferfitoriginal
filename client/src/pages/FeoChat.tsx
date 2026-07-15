import { useState, useRef, useEffect } from "react";
import { trpc } from "@/lib/trpc";
import DashboardLayout from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Card } from "@/components/ui/card";
import { Send, Sparkles, User, Loader2, MessageSquare } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";

export type ChatMessage = {
  role: "user" | "assistant";
  content: string;
};

const SUGGESTED_PROMPTS = [
  "¿Qué ejercicio puedo hacer hoy?",
  "Dame un tip de nutrición",
  "¿Cómo mantengo la racha?",
  "Motivame para entrenar",
];

export default function FeoChat() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const scrollAreaRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const chatMutation = trpc.social.chatWithFeo.useMutation({
    onSuccess: (data) => {
      setMessages((prev) => [...prev, { role: "assistant", content: data.reply }]);
    },
    onError: (err) => {
      toast.error("Feo no pudo responder", { description: err.message });
    },
  });

  useEffect(() => {
    const viewport = scrollAreaRef.current?.querySelector(
      "[data-radix-scroll-area-viewport]"
    ) as HTMLDivElement | null;
    if (viewport) {
      viewport.scrollTo({ top: viewport.scrollHeight, behavior: "smooth" });
    }
  }, [messages, chatMutation.isPending]);

  const handleSend = (content: string) => {
    const trimmed = content.trim();
    if (!trimmed || chatMutation.isPending) return;

    const newMessages: ChatMessage[] = [...messages, { role: "user", content: trimmed }];
    setMessages(newMessages);
    setInput("");

    chatMutation.mutate({
      message: trimmed,
      history: newMessages.slice(0, -1).map((m) => ({ role: m.role, content: m.content })),
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    handleSend(input);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend(input);
    }
  };

  return (
    <DashboardLayout>
      <div className="max-w-3xl mx-auto h-[calc(100vh-8rem)] md:h-[calc(100vh-6rem)] flex flex-col">
        <div className="mb-4 text-left">
          <h1 className="font-display text-3xl font-bold text-foreground flex items-center gap-2">
            <span className="text-accent">Feo</span> Chat
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            Habla con Feo, tu entrenador personal. Te motiva, te aconseja y te banca en cada serie.
          </p>
        </div>

        <Card className="flex-1 flex flex-col glass-panel overflow-hidden">
          <div ref={scrollAreaRef} className="flex-1 overflow-hidden">
            {messages.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center p-6 text-center text-muted-foreground">
                <div className="w-16 h-16 rounded-full bg-accent/10 border border-accent/20 flex items-center justify-center mb-4">
                  <MessageSquare className="w-8 h-8 text-accent" />
                </div>
                <p className="text-sm mb-6">Empezá una charla con Feo</p>
                <div className="flex flex-wrap justify-center gap-2 max-w-md">
                  {SUGGESTED_PROMPTS.map((prompt) => (
                    <button
                      key={prompt}
                      onClick={() => handleSend(prompt)}
                      disabled={chatMutation.isPending}
                      className="px-3 py-1.5 rounded-full text-xs border border-border/50 hover:border-accent/50 hover:bg-accent/10 transition-all disabled:opacity-50"
                    >
                      {prompt}
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <ScrollArea className="h-full">
                <div className="flex flex-col gap-4 p-4">
                  {messages.map((message, index) => (
                    <div
                      key={index}
                      className={cn(
                        "flex gap-3",
                        message.role === "user" ? "justify-end" : "justify-start"
                      )}
                    >
                      {message.role === "assistant" && (
                        <div className="w-8 h-8 rounded-full bg-accent/10 border border-accent/20 flex items-center justify-center shrink-0">
                          <Sparkles className="w-4 h-4 text-accent" />
                        </div>
                      )}
                      <div
                        className={cn(
                          "max-w-[80%] rounded-xl px-4 py-2.5 text-sm leading-relaxed whitespace-pre-wrap",
                          message.role === "user"
                            ? "bg-accent text-accent-foreground"
                            : "bg-muted text-foreground"
                        )}
                      >
                        {message.content}
                      </div>
                      {message.role === "user" && (
                        <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center shrink-0">
                          <User className="w-4 h-4 text-muted-foreground" />
                        </div>
                      )}
                    </div>
                  ))}
                  {chatMutation.isPending && (
                    <div className="flex gap-3 justify-start">
                      <div className="w-8 h-8 rounded-full bg-accent/10 border border-accent/20 flex items-center justify-center shrink-0">
                        <Sparkles className="w-4 h-4 text-accent" />
                      </div>
                      <div className="bg-muted rounded-xl px-4 py-2.5 flex items-center gap-2">
                        <Loader2 className="w-4 h-4 animate-spin text-muted-foreground" />
                        <span className="text-xs text-muted-foreground">Feo está pensando...</span>
                      </div>
                    </div>
                  )}
                </div>
              </ScrollArea>
            )}
          </div>

          <form
            onSubmit={handleSubmit}
            className="flex gap-2 p-4 border-t border-border/10 bg-background/50 items-end"
          >
            <Textarea
              ref={textareaRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Escribile a Feo..."
              className="flex-1 max-h-32 resize-none min-h-9 bg-background/50"
              rows={1}
            />
            <Button
              type="submit"
              size="icon"
              disabled={!input.trim() || chatMutation.isPending}
              className="shrink-0 h-[38px] w-[38px]"
            >
              {chatMutation.isPending ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Send className="w-4 h-4" />
              )}
            </Button>
          </form>
        </Card>
      </div>
    </DashboardLayout>
  );
}
