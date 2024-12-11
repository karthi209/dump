- name: Run version checks for {{ group_name }}
  block:
    - name: Check version for {{ item.name }}
      shell: "{{ item.command }}"
      register: version_output
      changed_when: false
      failed_when: false
      ignore_errors: true

    - name: Extract version for {{ item.name }}
      set_fact:
        tool_version: >-
          {{ version_output.stdout | default(version_output.stderr) | regex_search(item.regex, '\\1') | default('Not Installed') }}

    - name: Add tool version to results
      set_fact:
        version_results: >-
          {{ version_results | combine({
            group_name: (version_results[group_name] | default([])) + [
              {
                "name": item.name,
                "version": tool_version
              }
            ]
          }) }}
  loop: "{{ group_tools }}"
  loop_control:
    label: "{{ item.name }}"
