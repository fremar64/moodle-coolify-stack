# Course format learningmap

This course format allows you to use learningmaps (https://moodle.org/plugins/mod_learningmap) as the main page of your course. It requires mod_learningmap to be installed (at least version 0.9.9).

Editing your course is similar to format_topics - you can create your activities and structure them into sections as you are used to. But your students won't ever see this structure. You must have at least one learning map that your students can access. If there are several learning maps, the first one that the students can access is used (called the "main learning map"). This learning map will be displayed to students when they access the course.

Please note that
* activity completion must be enabled in order to use this course format,
* the course format must set activity completion to "manual completion" in the activity edit form (otherwise they won't be usable in the course),
* activities that do not have a view page (like mod_label, mod_unilabel, ...) cannot be used with this course format and 
* the backlink function of mod_learningmap is automatically enabled when using the course format (unless it is disabled site-wide).