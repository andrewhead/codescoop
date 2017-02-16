public class SymbolAppearance {

    private final String mSymbolName;
    private final int mLineNumber;
    private final int mStartPosition;
    private final int mEndPosition;

    public SymbolAppearance(String pSymbolName, int pLineNumber, int pStartPosition, 
            int pEndPosition) {
        this.mSymbolName = pSymbolName;
        this.mLineNumber = pLineNumber;
        this.mStartPosition = pStartPosition;
        this.mEndPosition = pEndPosition;
    }

    public String getSymbolName() {
        return this.mSymbolName;
    }

    public int getLineNumber() {
        return this.mLineNumber;
    }

    public int getStartPosition() {
        return this.mStartPosition;
    }

    public int getEndPosition() {
        return this.mEndPosition;
    }

    public boolean equals(Object other) {
        if (!(other instanceof SymbolAppearance)) {
            return false;
        }
        SymbolAppearance otherAppearance = (SymbolAppearance) other;
        return (
            otherAppearance.getSymbolName() == this.getSymbolName() &&
            otherAppearance.getLineNumber() == this.getLineNumber() &&
            otherAppearance.getStartPosition() == this.getStartPosition() &&
            otherAppearance.getEndPosition() == this.getEndPosition()
        );
    }

    public int hashCode() {
        return (
            this.mSymbolName.hashCode() *
            this.mLineNumber *
            this.mStartPosition *
            this.mEndPosition
        );
    }

}
