import formHelpers from "../modules/formHelpers";
import MultiLingualText from "./MultiLingualText";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import { Button, FormHelperText, FormLabel, Stack } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";

/**
 * Image file input disguised as a custom upload button.
 * If you pass in an image file object or blob, it will be displayed
 * along with the image caption.
 * @param image the image source file or image blob
 * @param caption
 * @param required sets the input field as required
 * @param onImageChange callback func which passes image file
 * @param onCaptionChange callback func which receives the new multilingual value
 * @returns {JSX.Element}
 * @constructor
 */
function ImageFileInput({ image, caption, required, onImageChange, onCaptionChange }) {
  caption = caption || formHelpers.initialTranslation;
  let src = {};
  if (image?.url) {
    src = image.url;
  }
  if (image instanceof Blob) {
    src = URL.createObjectURL(image);
  }
  return (
    <Stack spacing={1}>
      <FormLabel>Image:</FormLabel>
      <Button component="label" variant="contained" startIcon={<CloudUploadIcon />}>
        Set image
        <input
          type="file"
          name="image"
          accept=".jpg,.jpeg,.png"
          // zero opacity hides the input and allows form validation
          // error messages to popup, unlike 'hidden' attribute. 0px also
          // prevents validation errors from popping up, so use 1px.
          style={{ opacity: "0", width: "1px" }}
          required={required}
          onChange={(e) => onImageChange(e.target.files[0])}
        />
      </Button>
      <FormHelperText sx={{ mb: 2 }}>
        Use JPEG and PNG formats. Suggest using size 500x500 pixels or above to avoid
        display issues.
      </FormHelperText>
      {!isEmpty(src) && (
        <Stack gap={3}>
          <img src={src} alt={caption.en} />
          <MultiLingualText
            label="Caption"
            fullWidth
            value={caption}
            onChange={onCaptionChange}
          />
        </Stack>
      )}
    </Stack>
  );
}

export default ImageFileInput;
