//
// HexBokeh - A Fast DOF Shader With Hexagonal Apertures
//
// Copyright (C) 2014 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

//
// This shader is based on McIntosh's paper "Efficiently Simulating the Bokeh of
// Polygonal Apertures in a Post-Process Depth of Field Shader". For further
// details see the paper below.
//
// http://ivizlab.sfu.ca/media/DiPaolaMcIntoshRiecke2012.pdf
//

using UnityEngine;
using UnityEditor;
using System.Collections;

[CustomEditor(typeof(HexBokeh)), CanEditMultipleObjects]
public class HexBokehEditor : Editor
{
    SerializedProperty propFocalTarget;
    SerializedProperty propFocalLength;
    SerializedProperty propFocalSize;
    SerializedProperty propAperture;
    SerializedProperty propVisualize;
    SerializedProperty propNearBlur;
    SerializedProperty propSampleCount;
    SerializedProperty propSampleDist;

    void OnEnable()
    {
        propFocalTarget = serializedObject.FindProperty("focalTarget");
        propFocalLength = serializedObject.FindProperty("focalLength");
        propFocalSize   = serializedObject.FindProperty("focalSize");
        propAperture    = serializedObject.FindProperty("aperture");
        propVisualize   = serializedObject.FindProperty("visualize");
        propNearBlur    = serializedObject.FindProperty("nearBlur");
        propSampleCount = serializedObject.FindProperty("sampleCount");
        propSampleDist  = serializedObject.FindProperty("sampleDist");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.PropertyField(propFocalTarget);

        if (propFocalTarget.hasMultipleDifferentValues ||
            propFocalTarget.objectReferenceValue == null)
            EditorGUILayout.PropertyField(propFocalLength);

        EditorGUILayout.PropertyField(propFocalSize);
        EditorGUILayout.PropertyField(propAperture);
        EditorGUILayout.PropertyField(propVisualize, new GUIContent("Visualize CoC"));
        EditorGUILayout.PropertyField(propNearBlur);
        EditorGUILayout.PropertyField(propSampleCount);
        EditorGUILayout.PropertyField(propSampleDist, new GUIContent("Sample Distance"));

        serializedObject.ApplyModifiedProperties();
    }
}
