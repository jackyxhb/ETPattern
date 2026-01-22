
import plistlib
import sys

def inspect():
    with open('ETPattern.xcodeproj/project.pbxproj', 'rb') as f:
        pl = plistlib.load(f)
    
    objects = pl['objects']
    root_obj = objects[pl['rootObject']]
    main_group_uuid = root_obj['mainGroup']
    main_group = objects[main_group_uuid]
    
    print(f"Main Group UUID: {main_group_uuid}")
    print(f"Main Group Children: {len(main_group['children'])}")
    
    # Find ETPattern target
    targets = root_obj['targets']
    et_target = None
    for t_uuid in targets:
        t = objects[t_uuid]
        if t['name'] == 'ETPattern' and t['isa'] == 'PBXNativeTarget':
            et_target = t
            print(f"Found Target 'ETPattern': {t_uuid}")
            break
            
    if et_target:
        # Find Sources Build Phase
        for bp_uuid in et_target['buildPhases']:
            bp = objects[bp_uuid]
            if bp['isa'] == 'PBXSourcesBuildPhase':
                print(f"Found Sources Build Phase: {bp_uuid}")
                print(f"  Count: {len(bp['files'])}")
                
    # Find ETPattern Group (where source files likely live)
    # Recursively search for a group containing 'ContentView.swift'
    def find_group_with_file(group_uuid, filename):
        group = objects[group_uuid]
        if 'children' not in group: return None
        
        for child_uuid in group['children']:
            child = objects[child_uuid]
            if child.get('path') == filename:
                return group_uuid
            if child['isa'] == 'PBXGroup':
                res = find_group_with_file(child_uuid, filename)
                if res: return res
        return None

    app_group_uuid = find_group_with_file(main_group_uuid, 'ContentView.swift')
    if app_group_uuid:
        print(f"Found Group containing ContentView.swift: {app_group_uuid}")
        print(f"  Path: {objects[app_group_uuid].get('path', 'N/A')}")
    else:
        print("Could not find group with ContentView.swift")

inspect()
