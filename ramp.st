program ramp

#define MESSAGE(MSG) \
    sprintf(msg,#MSG);\
    printf("%s\n",msg);\
    pvPut(msg);

string msg;  assign msg   to "{P}i:ramp:msg";
float vset;  assign vset  to "{P}v:set";
float iset;  assign iset  to "{P}i:set";  monitor iset;
float imon;  assign imon  to "{P}i:rbk";  monitor imon;
float iramp; assign iramp to "{P}i:ramp"; monitor iramp;
int fault;   assign fault to "{P}fault";  monitor fault;
int enable; assign enable to "{P}i:ramp:enable"; monitor enable;
int abort; assign abort to "{P}i:ramp:abort"; monitor abort;

evflag ev_ramp; sync iramp ev_ramp;
evflag ev_abort; sync abort ev_abort;

float rampstep=555; float tolerance=20; int timeout=30;

int nsteps; int istep; float itarget; float istart; int count;

%{
extern double fabs(double);
int equals(float x1,float x2,float tolerance) { return fabs(x1-x2) < tolerance; }
}%

ss ramp {

    state start {

        entry {
            MESSAGE(Initialized.);
            efClear(ev_ramp);
        }

        when() {} state idle
    }

    state idle {

        entry {
            epicsThreadSleep(1);
        }

        when (enable==0 && efTestAndClear(ev_ramp)) {
            MESSAGE(Disabled, ramp ignored.)
        } state idle

        when (fault!=0 && efTestAndClear(ev_ramp)) {
            MESSAGE(Hardware fault, ramp ignored.)
        } state idle

        when (efTestAndClear(ev_ramp)) {
            MESSAGE(Ramp triggered.);
            vset = 60;
            pvPut(vset);
            epicsThreadSleep(1.01);
        } state ramp

    }

    state ramp {

        entry {
            count = 0;
            istart = imon;
            itarget = iramp;
            nsteps = (int)(fabs(itarget-istart)/rampstep) + 1;
            istep = 0;
            sprintf(msg,"Entered ramp: %.1f -> %.1f in %d steps",istart,itarget,nsteps);
            printf("%s\n",msg);
            pvPut(msg);
        }

        // try to set it again:
        when(delay(6.1) && 2>count) {
            count += 1;
            pvPut(iset);
        } state ramp

        // hardware fault, abort:
        when (fault != 0) {
            MESSAGE(Ramp aborted, hardware fault.);
        } state idle

        // disabled, abort:
        when (enable == 0) {
            MESSAGE(Ramp disabled.);
        } state idle

        // manual abort:
        when (efTestAndClear(abort)) {
            MESSAGE(Ramp aborted.);
        } state idle

        // timeout, abort:
        when (delay(timeout)) {
            MESSAGE(Ramp aborted, timeout reaching setpoint.);
        } state idle

        // restart ramp:
        when (efTestAndClear(ev_ramp)) {
        } state reramp

        // ramp succesfull:
        when(equals(imon, itarget, tolerance)) {
            sprintf(msg,"Ramp to %.1f finished sucecsfully.",itarget);
            printf("%s\n",msg);
            pvPut(msg);
        } state idle

        // go to the next ramp step:
        when(delay(1) && istep < nsteps && equals(imon, iset, tolerance)) {
            if (istep == nsteps-1) iset = itarget;
            else iset = istart + (istep+1)*(itarget>istart?1:-1)*rampstep;
            if (iset < rampstemp) iset=0;
            sprintf(msg,"Ramp step: #%d/%d, %.1f->%.1f->%.1f",istep+1,nsteps,istart,iset,itarget);
            printf("%s\n",msg);
            pvPut(msg);
            pvPut(iset);
            istep += 1;
            epicsThreadSleep(0.1);
        } state ramp

    }

    state reramp {
        when () {
            MESSAGE(Ramp aborted, reramping.);
        } state ramp
    }

}

