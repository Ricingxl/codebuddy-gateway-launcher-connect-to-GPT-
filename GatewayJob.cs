using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
// A non-inheritable job handle dies with the owning PowerShell process.
public sealed class GatewayJob : IDisposable {
    IntPtr job, process;
    [StructLayout(LayoutKind.Sequential)] struct Basic { public long a,b; public uint flags; public UIntPtr c,d; public uint e; public UIntPtr f; public uint g,h; }
    [StructLayout(LayoutKind.Sequential)] struct IO { public ulong a,b,c,d,e,f; }
    [StructLayout(LayoutKind.Sequential)] struct Limits { public Basic basic; public IO io; public UIntPtr a,b,c,d; }
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] struct Startup { public int cb; public string reserved,desktop,title; public uint x,y,xs,ys,xc,yc,fill,flags; public ushort show,reserved2; public IntPtr bytes,input,output,error; }
    [StructLayout(LayoutKind.Sequential)] struct PI { public IntPtr process,thread; public uint pid,tid; }
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateJobObject(IntPtr a,string n);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetInformationJobObject(IntPtr j,int c,ref Limits l,int s);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool CreateProcess(string app,StringBuilder cmd,IntPtr pa,IntPtr ta,bool inherit,uint flags,IntPtr env,string cwd,ref Startup si,out PI pi);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr j,IntPtr p);
    [DllImport("kernel32.dll",SetLastError=true)] static extern uint ResumeThread(IntPtr t);
    [DllImport("kernel32.dll")] static extern bool TerminateProcess(IntPtr p,uint code);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr p);
    [DllImport("kernel32.dll")] static extern uint WaitForSingleObject(IntPtr p,uint ms);
    [DllImport("kernel32.dll")] static extern bool GetExitCodeProcess(IntPtr p,out uint code);
    public GatewayJob(string app,string command,string cwd) {
        PI pi = new PI();
        try {
            job=CreateJobObject(IntPtr.Zero,null);
            if(job==IntPtr.Zero) throw new Win32Exception();
            Limits limits=new Limits(); limits.basic.flags=0x2000; // KILL_ON_JOB_CLOSE
            if(!SetInformationJobObject(job,9,ref limits,Marshal.SizeOf(typeof(Limits)))) throw new Win32Exception();
            Startup si=new Startup(); si.cb=Marshal.SizeOf(typeof(Startup));
            if(!CreateProcess(app,new StringBuilder(command),IntPtr.Zero,IntPtr.Zero,false,4,IntPtr.Zero,cwd,ref si,out pi)) throw new Win32Exception();
            process=pi.process;
            if(!AssignProcessToJobObject(job,process)) throw new Win32Exception();
            if(ResumeThread(pi.thread)==0xffffffff) throw new Win32Exception();
        } catch { if(process!=IntPtr.Zero) TerminateProcess(process,1); Dispose(); throw; }
        finally { if(pi.thread!=IntPtr.Zero) CloseHandle(pi.thread); }
    }
    public bool Exited { get { return WaitForSingleObject(process,0)==0; } }
    public uint ExitCode { get { uint code; GetExitCodeProcess(process,out code); return code; } }
    public void Dispose() { if(job!=IntPtr.Zero) { CloseHandle(job); job=IntPtr.Zero; } if(process!=IntPtr.Zero) { CloseHandle(process); process=IntPtr.Zero; } }
}
