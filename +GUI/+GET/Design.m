function design = Design( handles )
all_designs = get(handles.listbox_design, 'String');
selected_value = get(handles.listbox_design, 'Value');
design = all_designs{selected_value};
end % function
