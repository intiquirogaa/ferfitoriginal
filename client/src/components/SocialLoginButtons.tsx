import { useSignIn } from "@clerk/clerk-react";
import { useState } from "react";
import { Loader2 } from "lucide-react";

const isClerkConfigured = Boolean(import.meta.env.VITE_CLERK_PUBLISHABLE_KEY);

type Provider = "oauth_google" | "oauth_facebook";

export function SocialLoginButtons({
  className,
}: {
  className?: string;
}) {
  const { signIn } = useSignIn();
  const [loading, setLoading] = useState<Provider | null>(null);

  if (!isClerkConfigured) return null;

  const signInWith = async (strategy: Provider) => {
    if (!signIn) return;
    setLoading(strategy);
    try {
      await signIn.authenticateWithRedirect({
        strategy,
        redirectUrl: "/sso-callback",
        redirectUrlComplete: "/dashboard",
      });
    } catch (error) {
      console.error(`Error al iniciar sesión con ${strategy}:`, error);
      setLoading(null);
    }
  };

  return (
    <div className={`flex flex-col gap-2 ${className ?? ""}`}>
      <button
        type="button"
        onClick={() => signInWith("oauth_google")}
        disabled={loading !== null}
        className="flex items-center justify-center gap-2 rounded-lg border border-border/40 bg-background px-4 py-2.5 text-sm font-medium text-foreground transition-colors hover:bg-accent/10 disabled:opacity-60"
      >
        {loading === "oauth_google" ? (
          <Loader2 className="w-4 h-4 animate-spin" />
        ) : (
          <GoogleIcon className="w-4 h-4" />
        )}
        Continuar con Google
      </button>
      <button
        type="button"
        onClick={() => signInWith("oauth_facebook")}
        disabled={loading !== null}
        className="flex items-center justify-center gap-2 rounded-lg border border-border/40 bg-background px-4 py-2.5 text-sm font-medium text-foreground transition-colors hover:bg-accent/10 disabled:opacity-60"
      >
        {loading === "oauth_facebook" ? (
          <Loader2 className="w-4 h-4 animate-spin" />
        ) : (
          <FacebookIcon className="w-4 h-4" />
        )}
        Continuar con Facebook
      </button>
    </div>
  );
}

function GoogleIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.27-4.74 3.27-8.1Z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84A11 11 0 0 0 12 23Z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.1a6.6 6.6 0 0 1 0-4.2V7.06H2.18a11 11 0 0 0 0 9.88l3.66-2.84Z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1A11 11 0 0 0 2.18 7.06l3.66 2.84C6.71 7.3 9.14 5.38 12 5.38Z"
      />
    </svg>
  );
}

function FacebookIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="#1877F2"
        d="M24 12.07C24 5.4 18.63 0 12 0S0 5.4 0 12.07c0 6.02 4.39 11.01 10.13 11.93v-8.44H7.08v-3.49h3.05V9.41c0-3.02 1.79-4.69 4.53-4.69 1.31 0 2.68.24 2.68.24v2.97h-1.51c-1.49 0-1.96.93-1.96 1.89v2.25h3.33l-.53 3.49h-2.8V24C19.61 23.08 24 18.09 24 12.07Z"
      />
    </svg>
  );
}
