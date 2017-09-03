public class Range {

    private final int mStartLine;
    private final int mStartColumn;
    private final int mEndLine;
    private final int mEndColumn;

    public Range(int pStartLine, int pStartColumn, int pEndLine, int pEndColumn) {
        this.mStartLine = pStartLine;
        this.mStartColumn = pStartColumn;
        this.mEndLine = pEndLine;
        this.mEndColumn = pEndColumn;
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
        return ("[L" + this.getStartLine() + "C" + this.getStartColumn() + ", " +
                "L" + this.getEndLine() + "C" + this.getEndColumn() + "])");
    }

    public boolean equals(Object other) {
        if (!(other instanceof Range)) {
            return false;
        }
        Range otherAppearance = (Range) other;
        return (
            otherAppearance.getStartLine() == this.getStartLine() &&
            otherAppearance.getStartColumn() == this.getStartColumn() &&
            otherAppearance.getEndLine() == this.getEndLine() &&
            otherAppearance.getEndColumn() == this.getEndColumn()
        );
    }

    public int hashCode() {
        return (
            this.mStartLine *
            this.mStartColumn *
            this.mEndLine *
            this.mEndColumn
        );
    }

}
