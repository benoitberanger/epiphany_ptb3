function listbox_design_Callback(hObject, ~)
all_designs = get(hObject, 'String');
selected_value = get(hObject, 'Value');
design = all_designs{selected_value};
cfg = DESIGN.(design); % just run it
end % end
