> Document conservé des étapes précédentes. Voir [la validation de livraison](../VALIDATION.md) pour les résultats et limites à la publication. Les fichiers `.maintenance` cités ne sont pas inclus.

# Carnet de documents médicaux

Implemented approved notebook concept with local persistent copies, category and pathology filters, text search, date sorting, and file import/open/export/removal. Profile conditions and notebook personalization use the same persisted condition set. Documents may concern both conditions without duplicate storage. Supported files: PDF, JPG/JPEG, PNG, DOC/DOCX, at most 20 MiB. No backend or clinician transmission.

## Visual verification

Concept: generated ImageGen mockup `exec-df3a74cd-b497-471a-861a-4d96687c5dd3.png` in the task generated_images folder.
Flutter widget screenshots: `artifacts/documents-notebook.png`, `documents-list.png`, `documents-empty.png`, `documents-small.png`. Native Flutter rendering is used because this is a Flutter mobile app; browser testing would not validate its native file dialogs.

Compared concept and render using view_image: heading and subtitle, gradient notebook cover and circles, gradient primary action, search, two filter rows, chronological list and dividers, date/category/pathology metadata, contextual actions. Viewports: 390×844 and 320×740; narrow viewport additionally tested at 1.5 text scale.

Intentional adaptations: existing shared PageHeader and Material/Poppins icon system; extra category Autres; editable pathology configuration and local-storage caption; realistic file size/type; dual-condition badge; scrollable content and filters to preserve readable typography. Synthetic documents appear only in screenshot/test fixtures, never in the app. No unrelated copy added to the cover/header.

## Validation and limits

Repository tests verify durable copying after source deletion, restart restoration, dual-condition matching, removal, empty/unsupported rejection, and exact iOS staging cleanup without deleting the original. Widget tests verify import, search, general filter, open/export callbacks and responsive layout. File picker plugin is registered by Flutter pub get with desktop platforms disabled in the build process.

Native dialogs and iOS export still require device validation. The existing Samsung is intentionally not operated during this task to avoid interrupting the user's ongoing interaction. Files remain stored locally, rather than synchronized to a physician.
