//Example writing the whole thing in C# to show how much easier it is to do without explicit memory management

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class RasConstants
{
    public const int MaxEntryName = 256;
    public const int MAX_PATH = 260;
};

public enum ProfileType
{
    REN_User = 0x0,
    REN_AllUsers = 0x1
};

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct RasEntryName
{
    public int structSize;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MaxEntryName + 1)]
    public string entryName;
    public ProfileType profileType;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MAX_PATH + 1)]
    public string phonebookLocation;
};

public static class NativeMethods
{
    [DllImport("rasapi32.dll", SetLastError = true,
    CharSet = CharSet.Unicode,
    ThrowOnUnmappableChar = true)]
    public static extern int RasEnumEntries(
        [In] IntPtr reserved,
        [In] string phonebookLocation,
        [In, Out] RasEntryName[] rasEntryNameArray,
        [In, Out] ref int memorySize,
        [Out] out int rasEntriesCount
    );
};

internal static class Program
{
    public static void Main(string[] args)
    {
        int initialEntryAllocation = 1;
        int rasEntryNameSize = Marshal.SizeOf(typeof(RasEntryName));
        int entityCount = 0;
        int memoryAllocation = rasEntryNameSize * initialEntryAllocation;

        RasEntryName[] entries = new RasEntryName[initialEntryAllocation];
        for (int i = 0; i < initialEntryAllocation; i++)
        {
            entries[i].structSize = rasEntryNameSize;
        }

        List<RasEntryName> rasEntries = new List<RasEntryName>();

        int result = NativeMethods.RasEnumEntries(IntPtr.Zero, @"C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk", entries, ref memoryAllocation, out entityCount);

        if (result == 603)
        {
            entries = new RasEntryName[entityCount];

            for (int i = 0; i < entries.Length; i++)
            {
                entries[i].structSize = rasEntryNameSize;
            }

            result = NativeMethods.RasEnumEntries(IntPtr.Zero, @"C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk", entries, ref memoryAllocation, out entityCount);
            if (result != 0)
            {
                throw new Exception(result.ToString());
            }
                
            foreach (RasEntryName profileEntry in entries)
            {
                rasEntries.Add(profileEntry);
            }
        }
        else if (result == 0)
        {
            if (entityCount > 0)
            {
                foreach (RasEntryName profileEntry in entries)
                {
                    rasEntries.Add(profileEntry);
                }
            }
            else
            {
                Console.WriteLine("There are no profiles currently in rasphone.pbk");
            }
        }
        else
        {
            Console.WriteLine("Something went wrong, error code: " + result);
        }

        foreach (RasEntryName entity in rasEntries)
        {
            Console.WriteLine("Profile Name: " + entity.entryName);
        }
    }
}