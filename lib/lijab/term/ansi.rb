
module Term
   module ANSIMove
      module_function
      def to(line, col) "\033[#{line};#{col}H" end
      def up(lines) "\033[#{lines}A" end
      def down(lines) "\033[#{lines}B" end
      def fwd(cols) "\033[#{cols}C" end
      def back(cols) "\033[#{cols}D" end
   end
   module ANSI
      module_function
      def savepos() "\033[s" end
      def restorepos() "\033[u" end
      def title(s) "\033]2;#{s}\007" end
      def clear() "\033[2J" end
      def cleartoeol() "\033[K" end
      def clearline() "\r#{cleartoeol}" end
   end
end
