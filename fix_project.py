
import plistlib
import sys
import os
import uuid

PROJECT_PATH = 'ETPattern.xcodeproj/project.pbxproj'
ROOT_DIR = 'ETPattern' # Directory on disk to scan

def generate_uuid():
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def run():
    print(f"Loading {PROJECT_PATH}...")
    with open(PROJECT_PATH, 'rb') as f:
        pl = plistlib.load(f)
    
    objects = pl['objects']
    root_obj = objects[pl['rootObject']]
    main_group_uuid = root_obj['mainGroup']
    
    # 1. Find or Create ETPattern Group
    # Try to find existing group with path 'ETPattern' inside Main Group
    et_pattern_group_uuid = None
    main_group = objects[main_group_uuid]
    
    for child_uuid in main_group['children']:
        child = objects[child_uuid]
        if child.get('path') == 'ETPattern' or child.get('name') == 'ETPattern':
            et_pattern_group_uuid = child_uuid
            print(f"Found ETPattern Group: {et_pattern_group_uuid}")
            break
            
    if not et_pattern_group_uuid:
        print("Could not find ETPattern group. Aborting to avoid messing up root.")
        sys.exit(1)

    # 2. Find Sources Build Phase
    sources_build_phase_uuid = None
    targets = root_obj['targets']
    for t_uuid in targets:
        t = objects[t_uuid]
        if t['name'] == 'ETPattern':
             for bp_uuid in t['buildPhases']:
                bp = objects[bp_uuid]
                if bp['isa'] == 'PBXSourcesBuildPhase':
                    sources_build_phase_uuid = bp_uuid
                    print(f"Found Sources Build Phase: {sources_build_phase_uuid}")
                    break
    
    if not sources_build_phase_uuid:
        print("Could not find Sources Build Phase. Aborting.")
        sys.exit(1)

    # Helper to find child group by path/name
    def find_child_group(parent_uuid, name):
        parent = objects[parent_uuid]
        if 'children' not in parent: return None
        for child_uuid in parent['children']:
            child = objects[child_uuid]
            # STRICTLY check for PBXGroup to avoid FileReferences (folders)
            if (child.get('path') == name or child.get('name') == name) and child.get('isa') in ['PBXGroup', 'PBXVariantGroup']:
                return child_uuid
        return None

    # Helper to create group
    def create_group(parent_uuid, name):
        new_uuid = generate_uuid()
        objects[new_uuid] = {
            'isa': 'PBXGroup',
            'children': [],
            'path': name,
            'sourceTree': '<group>'
        }
        objects[parent_uuid]['children'].append(new_uuid)
        print(f"Created Group '{name}': {new_uuid}")
        return new_uuid

    # Helper to check if file exists in group
    def file_exists_in_group(group_uuid, filename):
        group = objects[group_uuid]
        if 'children' not in group:
            return False
        for child_uuid in group['children']:
            child = objects[child_uuid]
            if child['isa'] == 'PBXFileReference' and child.get('path') == filename:
                return True
        return False

    # Recursive scan and inject
    added_count = 0
    
    for root, dirs, files in os.walk(ROOT_DIR):
        # Calculate relative path components from ETPattern/
        rel_path = os.path.relpath(root, ROOT_DIR) 
        # If root IS ETPattern, rel_path is '.'
        
        # Determine current parent group in Pbxproj
        current_group_uuid = et_pattern_group_uuid
        
        if rel_path != '.':
            # Traverse/Create groups for each component
            components = rel_path.split(os.sep)
            for part in components:
                found = find_child_group(current_group_uuid, part)
                if not found:
                    found = create_group(current_group_uuid, part)
                current_group_uuid = found
        
        for f in files:
            if not f.endswith('.swift'): continue
            
            if not file_exists_in_group(current_group_uuid, f):
                # Add File Ref
                file_uuid = generate_uuid()
                objects[file_uuid] = {
                    'isa': 'PBXFileReference',
                    'path': f,
                    'sourceTree': '<group>',
                    'lastKnownFileType': 'sourcecode.swift'
                }
                objects[current_group_uuid]['children'].append(file_uuid)
                
                # Add Build File
                build_file_uuid = generate_uuid()
                objects[build_file_uuid] = {
                    'isa': 'PBXBuildFile',
                    'fileRef': file_uuid
                }
                objects[sources_build_phase_uuid]['files'].append(build_file_uuid)
                
                print(f"Added {f} to group {current_group_uuid}")
                added_count += 1
            else:
                # print(f"Skipping {f} (already in project)")
                pass

    print(f"Total files added: {added_count}")
    
    with open(PROJECT_PATH, 'wb') as f:
        plistlib.dump(pl, f)
    print("Saved project.pbxproj")

run()
