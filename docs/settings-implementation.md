> Document conservé des étapes précédentes. Voir [la validation de livraison](../VALIDATION.md) pour les résultats et limites à la publication. Les fichiers `.maintenance` cités ne sont pas inclus.

# Paramètres et page eCare+

## Direction retenue

Compact profile banner, grouped lists for personal space/preferences/help/privacy, and a real eCare+ presentation/help page with links to working functions. Apple Health profile/help organization and Material grouped lists inform the hierarchy, while the existing Poppins/blue design system is preserved.

References: https://support.apple.com/en-us/104997 and https://m3.material.io/foundations/layout/canonical-examples/overview

ImageGen concept (built-in tool): `C:/Users/LENOVO/.codex/generated_images/01a1353a-7d0b-75f3-8800-277274a7e445/exec-b3bdc51d-b4ec-4d48-9932-9dac8ce6a98a.png`.

## Verification of the rendered interface

Native Flutter widget rendering: `tool/settings_preview_test.dart`, with actual app theme, Poppins, Material icons and existing patient/brand assets. Browser testing is not applicable to this native Flutter surface. Screenshots: `artifacts/settings-page.png`, `settings-links.png`, `settings-ecare.png`, `settings-help.png`, `settings-data.png`, `settings-small.png`.

Compared via view_image at 390×844 and 320×740, with 1.5 text scale for screenshot and 2.0 for interaction tests:

- Titles/subtitles and section order match the intended hierarchy.
- Profile banner uses existing shared avatar, gradient and compact chevron action.
- List groups retain white surfaces, subtle dividers and readable tap targets.
- Blue gradients, font weights and outline icons match the app's existing component system.
- eCare+ actions link to constants/documents/agenda; help expands and provides useful destination buttons.
- Long labels and increased text scale wrap without overflow.

Intentional adaptations to concept: use existing patient photo and real logo instead of generated placeholders; keep established entry label “À propos de eCARE+”; theme/language line has no chevron because it is informational; appointment reminder layout wraps for accessibility; data copy precisely distinguishes durable documents/conditions from session-only data. Native typography may require scrolling beyond the concept's compressed overview. No cloud privacy claims or fake support addresses are introduced.

## Functional boundaries

Appointment switch continues controlling in-app agenda notifications, not OS notifications. Language/theme remain French/light information. Logout clears CareData and does not remove DocumentLibrary files. Privacy and terms text is updated to reflect implemented local documents and pathology persistence. The guide distinguishes export copies from notebook entries. Licenses open the native Flutter license page.

Tests cover actual about-page navigation, expandable guide and document action, local-data explanation, enlarged-text layout, reminder behavior, logout and legal-page navigation. No phone interaction or installation is performed during this task.
