# Week 7 Tuong to Lap Safe RAG Filtering

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Define safe rules for using Tuong's document type predictions in RAG filtering to avoid incorrect filtering due to overconfident wrong predictions.

## Background

Tuong's Week 6 evaluation showed that document type predictions can be overconfident and sometimes incorrect. Using these predictions as hard filters in RAG retrieval could:

1. **Filter out relevant chunks** if prediction is wrong
2. **Reduce retrieval quality** by limiting search space incorrectly
3. **Cause user confusion** when valid documents are excluded

## Safe Filtering Rules

### Rule 1: Status-Based Filtering

**Only use document_type as a hard filter when:**
- `prediction_status = "accepted"`
- `confidence >= 0.80`
- `manual_reviewed = true` OR `trusted_model_version = true`

**Implementation:**
```python
def should_use_document_type_filter(prediction: dict) -> bool:
    """Determine if document type prediction is safe for hard filtering."""
    return (
        prediction.get("prediction_status") == "accepted" and
        prediction.get("confidence", 0) >= 0.80 and
        (prediction.get("manual_reviewed") or prediction.get("trusted_model_version"))
    )
```

### Rule 2: Soft Metadata by Default

**Default behavior:**
- Use document_type as **soft metadata only**
- Include document_type in response metadata
- Do NOT use document_type as a hard filter unless Rule 1 is satisfied

**Implementation:**
```python
def apply_safe_document_type_filter(
    chunks: list,
    document_type_filter: str,
    prediction: dict
) -> list:
    """Apply document type filter safely."""
    if should_use_document_type_filter(prediction):
        # Safe to use as hard filter
        return [
            c for c in chunks
            if c.get("metadata", {}).get("document_type") == document_type_filter
        ]
    else:
        # Use as soft metadata only - return all chunks
        # Include filter information in metadata
        for chunk in chunks:
            chunk.setdefault("metadata", {})["filter_applied"] = False
            chunk["metadata"]["filter_reason"] = "low_confidence_prediction"
        return chunks
```

### Rule 3: Low Confidence Handling

**When confidence < 0.80:**
- Ignore document_type for filtering
- Include prediction in metadata for transparency
- Log that filter was not applied due to low confidence

**Implementation:**
```python
def handle_low_confidence_prediction(
    chunks: list,
    prediction: dict
) -> list:
    """Handle low confidence predictions safely."""
    if prediction.get("confidence", 0) < 0.80:
        for chunk in chunks:
            chunk.setdefault("metadata", {})["document_type_prediction"] = prediction.get("document_type")
            chunk["metadata"]["prediction_confidence"] = prediction.get("confidence")
            chunk["metadata"]["filter_skipped_reason"] = "low_confidence"
    return chunks
```

## Filtering Modes

### Mode 1: No Filtering (Default)

**When to use:**
- Low confidence predictions (< 0.80)
- Prediction status not "accepted"
- No manual review

**Behavior:**
- Return all chunks
- Include document_type in metadata
- Do not filter by document_type

### Mode 2: Soft Filtering

**When to use:**
- Medium confidence (0.70 - 0.79)
- Prediction status "pending"

**Behavior:**
- Return all chunks
- Sort results by document_type match
- Boost similarity score for matching document_type

### Mode 3: Hard Filtering

**When to use:**
- High confidence (>= 0.80)
- Prediction status "accepted"
- Manual reviewed or trusted model

**Behavior:**
- Filter chunks by document_type
- Return only matching chunks
- Apply strict filter

## RAG Integration

### Retrieval with Safe Filtering

```python
from ai.rag.retriever import Retriever

def retrieve_with_safe_document_type_filter(
    retriever: Retriever,
    query: str,
    document_type: str,
    prediction: dict,
    top_k: int = 5
) -> list:
    """Retrieve with safe document type filtering."""
    
    # Check if safe to use hard filter
    if should_use_document_type_filter(prediction):
        # Use hard filter
        filter_metadata = {"document_type": document_type}
        results = retriever.retrieve(
            query,
            top_k=top_k,
            filter_metadata=filter_metadata
        )
        for result in results:
            result["metadata"]["filter_mode"] = "hard"
            result["metadata"]["filter_applied"] = True
    else:
        # Use soft metadata only
        results = retriever.retrieve(query, top_k=top_k)
        for result in results:
            result["metadata"]["filter_mode"] = "none"
            result["metadata"]["filter_applied"] = False
            result["metadata"]["document_type_prediction"] = prediction.get("document_type")
            result["metadata"]["prediction_confidence"] = prediction.get("confidence")
    
    return results
```

### Response Metadata

**Include filtering information in RAG response:**

```json
{
  "question": "What is the DataFlow pipeline?",
  "retrieved_context": [...],
  "citations": [...],
  "metadata": {
    "document_type_filter": "technical_report",
    "filter_mode": "none",
    "filter_applied": false,
    "filter_reason": "low_confidence_prediction",
    "prediction_confidence": 0.65,
    "prediction_status": "pending"
  }
}
```

## UI Display Guidelines

### For Phi/Hung

**When filter is applied (hard mode):**
- Show filter badge: "Filtered by: Technical Report"
- Show confidence score: "Confidence: 85%"
- Show status: "Status: Accepted"

**When filter is NOT applied (soft/none mode):**
- Show warning: "Document type filter not applied due to low confidence"
- Show prediction: "Predicted type: Technical Report (65% confidence)"
- Show reason: "Reason: Prediction not manually reviewed"

**Example UI:**

```
┌─────────────────────────────────────────┐
│ Retrieved Results                        │
├─────────────────────────────────────────┤
│ ⚠️ Document type filter not applied     │
│ Predicted: Technical Report (65%)       │
│ Reason: Low confidence prediction        │
├─────────────────────────────────────────┤
│ Result 1: DataFlow pipeline...          │
│ Page 4 • Similarity: 0.84               │
└─────────────────────────────────────────┘
```

## Prediction Metadata Schema

### Required Fields

```json
{
  "document_type": "technical_report",
  "confidence": 0.85,
  "prediction_status": "accepted",
  "manual_reviewed": true,
  "trusted_model_version": true,
  "model_version": "tuong_model_v2.1",
  "predicted_at": "2026-07-16T01:42:00Z"
}
```

### Field Definitions

- **document_type** (string): Predicted document type
- **confidence** (float): Prediction confidence [0.0, 1.0]
- **prediction_status** (string): "accepted", "pending", "rejected"
- **manual_reviewed** (boolean): Whether prediction was manually reviewed
- **trusted_model_version** (boolean): Whether model version is trusted
- **model_version** (string): Model version identifier
- **predicted_at** (timestamp): When prediction was made

## Testing Safe Filtering

### Test Case 1: High Confidence, Accepted

```python
prediction = {
    "document_type": "technical_report",
    "confidence": 0.85,
    "prediction_status": "accepted",
    "manual_reviewed": True
}

assert should_use_document_type_filter(prediction) == True
```

### Test Case 2: Low Confidence

```python
prediction = {
    "document_type": "technical_report",
    "confidence": 0.65,
    "prediction_status": "pending",
    "manual_reviewed": False
}

assert should_use_document_type_filter(prediction) == False
```

### Test Case 3: High Confidence, Not Reviewed

```python
prediction = {
    "document_type": "technical_report",
    "confidence": 0.85,
    "prediction_status": "pending",
    "manual_reviewed": False,
    "trusted_model_version": False
}

assert should_use_document_type_filter(prediction) == False
```

## Error Handling

### Missing Prediction Data

**If prediction data is missing:**
- Default to no filtering
- Log warning about missing prediction
- Include "prediction_missing" in metadata

### Invalid Confidence Values

**If confidence is outside [0.0, 1.0]:**
- Clamp to valid range
- Log warning about invalid confidence
- Treat as low confidence (< 0.80)

### Unknown Document Type

**If document_type is unknown:**
- Do not apply filter
- Log warning about unknown type
- Include "unknown_type" in metadata

## Coordination with Tuong

### Lap Needs from Tuong

1. **Document type label list**: Valid document type values
2. **Confidence thresholds**: Recommended confidence thresholds
3. **Status rules**: Definition of accepted/pending/rejected
4. **Trusted model versions**: Which model versions are trusted
5. **Manual review process**: How predictions are manually reviewed

### Tuong Needs from Lap

1. **Filter behavior**: How RAG uses document type predictions
2. **Feedback loop**: Which predictions were used/not used and why
3. **Performance metrics**: Impact of filtering on retrieval quality
4. **Error cases**: Examples of incorrect filtering

## Week 7 Status

**Status**: Safe filtering rules defined

**Implementation**: Ready for integration

**Testing**: Test cases defined

**Coordination**: Pending Tuong's input on thresholds and status rules

**Next Steps**:
1. Confirm confidence thresholds with Tuong
2. Confirm status definitions with Tuong
3. Integrate safe filtering into RAG retriever
4. Add filtering metadata to RAG response
5. Test with real predictions from Tuong
6. Monitor filtering impact on retrieval quality

## Notes for Tuong

1. **Confidence Thresholds**: Please confirm if 0.80 is appropriate
2. **Status Definitions**: Please define accepted/pending/rejected criteria
3. **Trusted Models**: Please identify which model versions are trusted
4. **Manual Review**: Please describe manual review process
5. **Feedback Loop**: Lap will provide feedback on filter usage

## Notes for Phi/Hung

1. **Filter Status**: Check filter_mode in response metadata
2. **Warning Display**: Show warnings when filter not applied
3. **Confidence Display**: Show prediction confidence when available
4. **Reason Display**: Show reason for filter/not applied decision
5. **User Control**: Consider allowing users to override filter

## Conclusion

Safe document type filtering prevents incorrect filtering due to overconfident wrong predictions. By using status, confidence, and manual review as gates, RAG can safely leverage Tuong's predictions while maintaining retrieval quality.

The default behavior is to use document_type as soft metadata only, applying hard filtering only when predictions meet strict quality criteria.
