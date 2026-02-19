#let IMAGE_BOX_MAX_WIDTH = 120pt
#let IMAGE_BOX_MAX_HEIGHT = 50pt

#let supported-langs = ("en", "fr", "ar")

#let full-page-chapter = state("full-page-chapter", false)

#let project(
  title: "",
  subtitle: none,
  header: none,
  school-logo: none,
  company-logo: none,
  authors: (),
  mentors: (),
  jury: (),
  branch: none,
  academic-year: none,
  french: false,
  lang: none,
  footer-text: "ENSIAS",
  features: (),
  heading-numbering: "1.1",
  accent-color: rgb("#ff4136"),
  defense-date: none,
  body
) = {

  // --- Embedded dictionary ---
  let dict = (
    mentor: "Mentor",
    mentor_plural: "Mentors",
    jury: "Jury",
    author: "Author",
    author_plural: "Authors",
    academic_year: "Academic year",
    figures_table: "Table of figures",
    tables_table: "Table of tables",
    chapter: "Chapter",
    defended_on_pre_date: "Defended on",
    defended_on_post_date: "in front of the jury composed of",
  )

  set document(author: authors, title: title)

  set text(lang: "en", size: 13pt)
  set heading(numbering: heading-numbering)

  // --- ARTICLE STYLE HEADINGS (no chapters) ---
  show heading: it => {
    v(6pt)
    text(weight: "bold")[#it]
    v(10pt)
  }

  if header != none {
    h(1fr)
    box(width: 60%)[
      #align(center)[
        #text(weight: "medium")[#header]
      ]
    ]
    h(1fr)
  }

  block[
    #box(height: IMAGE_BOX_MAX_HEIGHT, width: IMAGE_BOX_MAX_WIDTH)[
      #align(start + horizon)[
        #if school-logo == none {
          image("images/ENSIAS.svg")
        } else {
          school-logo
        }
      ]
    ]
    #h(1fr)
    #box(height: IMAGE_BOX_MAX_HEIGHT, width: IMAGE_BOX_MAX_WIDTH)[
      #align(end + horizon)[
        #company-logo
      ]
    ]
  ]

  align(center + horizon)[
    #if subtitle != none {
      text(size: 14pt, tracking: 2pt)[
        #smallcaps[#subtitle]
      ]
    }
    #line(length: 100%, stroke: 0.5pt)
    #text(size: 20pt, weight: "bold")[#title]
    #line(length: 100%, stroke: 0.5pt)
  ]

  box()
  h(1fr)
  grid(
    columns: (auto, 1fr, auto),
    [
      #if authors.len() > 0 {
        [
          #text(weight: "bold")[
            #if authors.len() > 1 { dict.author_plural } else { dict.author }
            #linebreak()
          ]
          #for author in authors {
            [#author #linebreak()]
          }
        ]
      }
    ],
    [
      #if mentors != none and mentors.len() > 0 {
        align(end)[
          #text(weight: "bold")[
            #if mentors.len() > 1 { dict.mentor_plural } else { dict.mentor }
            #linebreak()
          ]
          #for mentor in mentors {
            mentor
            linebreak()
          }
        ]
      }

      #if defense-date == none and jury != none and jury.len() > 0 {
        align(end)[
          *#dict.jury* #linebreak()
          #for prof in jury {
            [#prof #linebreak()]
          }
        ]
      }
    ]
  )

  align(center + bottom)[
    #if defense-date != none and jury != none and jury.len() > 0 {
      [*#dict.defended_on_pre_date #defense-date #dict.defended_on_post_date:*]
      align(center)[
        #for prof in jury {
          [#prof #linebreak()]
        }
      ]
      v(60pt)
    }
    #if branch != none {
      branch
      linebreak()
    }
    #if academic-year != none {
      [#dict.academic_year: #academic-year]
    }
  ]

  pagebreak()

  // Table of contents ONLY
  set page(footer: none)
  outline(depth: 3, indent: auto)

  set page(
    numbering: "1",
    number-align: center,
    footer: context {
      let page-number = counter(page).get().at(0);
      if page-number > 1 {
        line(length: 100%, stroke: 0.5pt)
        v(-2pt)
        text(size: 12pt)[
          #footer-text
          #h(1fr)
          #page-number
        ]
      }
    }
  )

  pagebreak()

  body
}