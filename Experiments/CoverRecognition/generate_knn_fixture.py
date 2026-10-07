"""Generate a tiny vector-only Core ML kNN fixture; not an image-cover model.

Run with an isolated coremltools environment. The output is kept outside Git.
"""
import sys
from coremltools.models.nearest_neighbors import KNearestNeighborsClassifierBuilder
from coremltools.models.utils import save_spec

builder = KNearestNeighborsClassifierBuilder(
    input_name="embedding",
    output_name="bookID",
    number_of_dimensions=3,
    default_class_label="unknown",
    number_of_neighbors=1,
    index_type="linear",
)
builder.spec.description.metadata.shortDescription = "Vector-only update lifecycle fixture, not a book-cover model"
builder.spec.description.metadata.author = "CoverRecognition PoC"
builder.spec.description.metadata.license = "Generated test fixture"
save_spec(builder.spec, sys.argv[1])
print("updatable:", builder.spec.isUpdatable)
print("input:", builder.spec.description.input[0].name, list(builder.spec.description.input[0].type.multiArrayType.shape))
print("output:", builder.spec.description.output[0].name)
