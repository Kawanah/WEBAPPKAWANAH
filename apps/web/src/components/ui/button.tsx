import * as React from "react";
import { cn } from "@/lib/utils";

const baseClasses = "inline-flex items-center justify-center rounded-lg text-sm font-medium transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:cursor-not-allowed disabled:opacity-60";

const variants = {
  primary: "bg-primary text-white hover:bg-primary/90",
  secondary: "border border-primary text-primary hover:bg-primary/10",
  ghost: "text-primary hover:bg-primary/10"
} as const;

type Variant = keyof typeof variants;

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: Variant;
};

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "primary", ...props }, ref) => (
    <button
      ref={ref}
      className={cn(baseClasses, variants[variant], className)}
      {...props}
    />
  )
);

Button.displayName = "Button";
