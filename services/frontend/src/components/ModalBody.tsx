interface ModalBodyProps {
  children: React.ReactNode;
}

export function ModalBody({ children }: ModalBodyProps) {
  return (
    <div className="px-6 py-4">
      {children}
    </div>
  );
}

