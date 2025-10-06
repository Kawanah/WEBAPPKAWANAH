import * as React from "react";
import { cn } from "@/lib/utils";

type InputProps = React.InputHTMLAttributes<HTMLInputElement> & {
  leftIcon?: React.ReactNode;
};

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, leftIcon, ...props }, ref) => {
    return (
      <div className="relative">
        {leftIcon ? (
          <span className="pointer-events-none absolute inset-y-0 left-0 flex w-10 items-center justify-center text-neutral-600">
            {leftIcon}
          </span>
        ) : null}
        <input
          ref={ref}
          className={cn(
            "h-11 w-full rounded-lg border border-neutral-300 bg-white px-3 text-sm text-neutral-900 shadow-sm transition focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40",
            leftIcon ? "pl-11" : "",
            className
          )}
          {...props}
        />
      </div>
    );
  }
);

Input.displayName = "Input";

export { Input };
