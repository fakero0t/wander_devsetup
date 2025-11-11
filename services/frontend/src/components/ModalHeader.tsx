interface ModalHeaderProps {
  children: React.ReactNode;
}

export function ModalHeader({ children }: ModalHeaderProps) {
  return (
    <div className="px-6 py-4 border-b border-gray-200">
      <h2 className="text-xl font-semibold">{children}</h2>
    </div>
  );
}

