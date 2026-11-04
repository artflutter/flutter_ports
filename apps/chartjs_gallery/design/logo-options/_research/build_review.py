"""Build the local logo comparison folders from verified review metadata."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
RESEARCH = ROOT / '_research'
refs = json.loads((RESEARCH / 'references.json').read_text())
reviews = json.loads((RESEARCH / 'reviews.json').read_text())
by_ref = {r['id']: r for r in refs}
catalog = json.loads((ROOT / 'catalog.json').read_text())
by_concept = {r['id']: r for r in catalog}
assert set(by_concept) == {r['id'] for r in reviews}

# Keep original prompt batches intact as the provenance record.
archive = ROOT / '_prompts'
archive.mkdir(exist_ok=True)
for original in ROOT.glob('*.txt'):
    if original.name.startswith('similarity-review-'):
        target = RESEARCH / original.name
    else:
        target = archive / original.name
    if target.exists():
        if target.read_bytes() != original.read_bytes():
            raise RuntimeError(f'Conflicting archive: {target}')
        original.unlink()
    else:
        original.rename(target)

# Record the actual image inspection, not only download success.
for ref in refs:
    ref['visual_review'] = 'Inspected in local browser contact sheet on 2026-11-02'
    ref['download_status'] = 'downloaded and visually verified'
    ref.pop('error', None)
    if ref['id'] == 'asr-bot':
        ref['name'] = 'ASR Transportes delivery mascot'
        ref['identification_note'] = 'Helmeted delivery character; do not assume it is a robot.'
    if ref['id'] == 'cj':
        ref['identification_note'] = 'Image hosted on NdotLight depicts CJ; not NdotLight branding.'
    if ref['id'] in ('autodesk', 'office', 'gemini'):
        ref['version_note'] = 'Specific historical/versioned artwork; not asserted to be the current logo.'
    p = RESEARCH / ref['file']
    assert hashlib.sha256(p.read_bytes()).hexdigest() == ref['sha256']
(RESEARCH / 'references.json').write_text(json.dumps(refs, indent=2) + '\n')

index = ['# Flutter Ports — logo comparison catalog', '',
    '35 generated concepts, each with its own folder. Open a concept’s review '
    'in Markdown Preview to see our board beside the downloaded comparisons.', '',
    '**Checked: 2 November 2026.** External images below are visual comparisons, '
    'not identified sources of the image generator’s output. Actual earlier '
    'concept inputs are labeled separately. No result establishes copying, '
    'originality, or trademark clearance.', '',
    '**Review first:** [07 Aperture P](07-aperture-p/README.md), '
    '[12 Folded Gate](12-folded-gate/README.md), '
    '[14 Woven F](14-woven-f/README.md), '
    '[22 Gecko](22-gecko/README.md). '
    'The earlier [01B](01b-portal-no-triangle/README.md) and '
    '[11 Impossible Door](11-impossible-door/README.md) also retain the Office resemblance.', '',
    '| Concept | Our board | Comparisons | Visual assessment |',
    '| --- | --- | --- | --- |']

for row in reviews:
    dest = ROOT / row['id']
    concept = dest / 'concept.png'
    assert hashlib.sha256(concept.read_bytes()).hexdigest() == by_concept[row['id']]['sha256']
    local_refs = dest / 'references'
    local_refs.mkdir(exist_ok=True)
    sources = []
    cells = []
    for ref_id in row['references']:
        ref = by_ref[ref_id]
        src = RESEARCH / ref['file']
        target = local_refs / src.name
        shutil.copy2(src, target)
        local = 'references/' + target.name
        sources.append({**ref, 'file': target.name, 'role': 'Visual comparison; not known generation input'})
        name = html.escape(ref['name'])
        cells.append(f'**[{name}]({ref["page_url"]})**<br>'
            f'[<img src="{local}" alt="{name}" width="340">]({local})')
    for parent in row['parents']:
        target = local_refs / ('input-' + parent + '.png')
        parent_file = ROOT / parent / 'concept.png'
        if not parent_file.exists() and parent == '01-portal':
            parent_file = Path('/Users/vasilich/.codex/generated_images/'
                '01a19c7b-c1c1-7c01-889d-62009dd31595/'
                'exec-5008c545-b1e5-400d-89ff-7f7cff416eef.png')
        if not target.exists():
            shutil.copy2(parent_file, target)
        sources.append({
            'id': parent, 'name': 'Our earlier concept ' + parent,
            'file': target.name, 'role': 'Actual earlier concept used for the edit/refinement',
            'source': ('../../' + parent + '/concept.png'
                if (ROOT / parent / 'concept.png').exists()
                else 'Original generated output, recovered as lineage reference only'),
            'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        })
    (local_refs / 'sources.json').write_text(json.dumps(sources, indent=2) + '\n')
    (local_refs / 'README.md').write_text(
        '# Comparison references\n\n'
        'External images are unchanged copies for local visual review. '
        'They are not Flutter Ports assets, endorsements, or evidence of copying. '
        'Source URLs, attribution, retrieval details and hashes are in '
        '[sources.json](sources.json). Original rights remain with their holders; '
        'no reuse permission is inferred.\n\n'
        'Files beginning with `input-` are our earlier concept boards that were '
        'actually used in the edit/refinement, not third-party comparisons.\n')
    own = '[<img src="concept.png" alt="Our generated concept" width="620">](concept.png)'
    doc = [f'# {row["id"]} — {row["title"]}', '',
        '[All concepts](../README.md) · [Full-size concept](concept.png) · '
        '[Original prompt](prompt.txt) · [Sources and hashes](references/sources.json)', '',
        f'**Visual assessment: {row["assessment"]}.**', '',
        '| Our generated concept | Existing work for comparison |',
        '| --- | --- |',
        '| ' + own + ' | ' + '<br><br>'.join(cells) + ' |', '',
        '## What is similar, and what differs', '', row['comparison'], '',
        '## Actual generation provenance', '', row['provenance'], '']
    if row['parents']:
        doc += ['Earlier concept inputs:', '']
        for parent in row['parents']:
            doc += [f'- [{parent}](references/input-{parent}.png)']
        doc += ['']
    doc += ['An existing brand named in a negative prompt (for example, “do not '
            'resemble …”) is an exclusion, not evidence that its image was used.', '',
            '## Search record', '',
            f'Reviewed {row["reviewed_on"]}. {row["review_type"]}', '',
            'Search queries used for this design or its family:', '']
    doc += ['- ' + q for q in row['queries']]
    doc += ['', 'A missing close match means only that this bounded search did '
            'not establish one. It is not a uniqueness claim. Comparisons can '
            'be historical marks or shared design archetypes; refer to the '
            'source metadata for versions and attribution.', '']
    (dest / 'README.md').write_text('\n'.join(doc))
    prompt = dest / 'prompt.txt'
    text = prompt.read_text()
    archive_name = by_concept[row['id']]['prompt_archive']
    text = text.replace('Source archive: ../' + archive_name,
                        'Source archive: ../_prompts/' + archive_name)
    prompt.write_text(text)
    by_concept[row['id']].update(title=row['title'],review='README.md',
        references=row['references'],assessment=row['assessment'],
        reviewed_on=row['reviewed_on'],parents=row['parents'])
    index.append('| **[' + row['id'] + ' · ' + row['title'] + ']('
        + row['id'] + '/README.md)** | [<img src="' + row['id']
        + '/concept.png" width="200" alt="' + html.escape(row['title'])
        + '">](' + row['id'] + '/concept.png) | '
        + ', '.join(by_ref[k]['name'] for k in row['references'])
        + ' | ' + row['assessment'] + ' |')

index += ['', '## Folder contents', '',
    '- `concept.png`: unchanged original generated board.',
    '- `prompt.txt`: original prompt and pointer to the preserved batch archive.',
    '- `README.md`: side-by-side review, similarities, differences and provenance.',
    '- `references/`: downloaded comparison images, actual prior-concept inputs '
    'where applicable, and `sources.json`.', '',
    'Shared archives: [_prompts](_prompts/) and '
    '[_research](_research/README.md). All prior root-level PNGs have moved into '
    'their correspondingly named folders as `concept.png`; hashes verify that '
    'the artwork itself has not changed.', '']
(ROOT / 'README.md').write_text('\n'.join(index))
(ROOT / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
(RESEARCH / 'README.md').write_text('''# Research record

This is a preliminary visual comparison of 35 generated concepts, checked on
2 November 2026. It uses descriptive image/web searches and inspection of actual
raster images. No reverse-image-upload search or exhaustive register search was
performed. It cannot determine a model's training sources or prove copying.

- [Review metadata](reviews.json): concept-specific observations and queries.
- [Reference manifest](references.json): URLs, attribution, timestamps and hashes.
- `assets/`: unchanged downloaded public references, visually inspected.
- [Previous shortlist review](similarity-review-2026-11-02.txt): earlier limited
  review preserved as history; the per-concept files contain the current review.
- `build_review.py`: rebuilds Markdown comparisons and local reference copies.

The image search described some assets inaccurately. Visual inspection corrected
the CJ/NdotLight attribution and the ASR mascot description. No access-denied
screens or HTML error bodies are included as logo references. MosaicML and Apache
Beam were inspected but rejected as close comparisons; their files remain in this
research cache, not presented as close matches beside those concepts.

External comparison media are not product assets. They retain the rights and
restrictions of their original owners; source links are provided without assuming
reuse permission or assigning the repository's MIT license to outside artwork.
The local review does not change the official-site application or publish these
third-party marks.
''')
print(f'Built {len(reviews)} reviews using {len(refs)} inspected source images.')
