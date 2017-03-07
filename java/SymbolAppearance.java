public class SymbolAppearance {

    private final String mSymbolName;
    private final int mStartLine;
    private final int mStartColumn;
    private final int mEndLine;
    private final int mEndColumn;

    public SymbolAppearance(String pSymbolName, int pStartLine, int pStartColumn, 
            int pEndLine, int pEndColumn) {
        this.mSymbolName = pSymbolName;
        this.mStartLine = pStartLine;
        this.mStartColumn = pStartColumn;
        this.mEndLine = pEndLine;
        this.mEndColumn = pEndColumn;
    }

    public String getSymbolName() {
        return this.mSymbolName;
    }

    public int getStartLine() {
        return this.mStartLine;
    }

    public int getStartColumn() {
        return this.mStartColumn;
    }

    public int getEndLine() {
        return this.mEndLine;
    }

    public int getEndColumn() {
        return this.mEndColumn;
    }

    public String toString() {
        return ("(" + this.getSymbolName() + ": " +
                "[L" + this.getStartLine() + "C" + this.getStartColumn() + ", " +
                "L" + this.getEndLine() + "C" + this.getEndColumn() + "])");
    }

    public boolean equals(Object other) {
        if (!(other instanceof SymbolAppearance)) {
            return false;
        }
        SymbolAppearance otherAppearance = (SymbolAppearance) other;
        return (
            otherAppearance.getSymbolName() == this.getSymbolName() &&
            otherAppearance.getStartLine() == this.getStartLine() &&
            otherAppearance.getStartColumn() == this.getStartColumn() &&
            otherAppearance.getEndLine() == this.getEndLine() &&
            otherAppearance.getEndColumn() == this.getEndColumn()
        );
    }

    public int hashCode() {
        return (
            this.mSymbolName.hashCode() *
            this.mStartLine *
            this.mStartColumn *
            this.mEndLine *
            this.mEndColumn
        );
    }

}
